import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import { FlutterPage } from '@ohos/flutter_ohos';
import { AddFormMenuItem, promptAction, SymbolGlyphModifier, uiMaterial } from '@kit.ArkUI';
import { formBindingData } from '@kit.FormKit';
import { preferences } from '@kit.ArkData';
import { HdsAnimationMode, hdsMaterial, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { deviceInfo } from '@kit.BasicServicesKit';

let storage = LocalStorage.getShared();

const TAG = 'Index';
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS';
const EVENT_TAB_SWITCH = 'EVENT_TAB_SWITCH';
const EVENT_CHANGE_TAB = 'EVENT_CHANGE_TAB';
const EVENT_TOP_SEARCH = 'EVENT_TOP_SEARCH';
const EVENT_TOP_MSG = 'EVENT_TOP_MSG';
const EVENT_TOP_MINE = 'EVENT_TOP_MINE';
const EVENT_HOME_TAB_CHANGE = 'EVENT_HOME_TAB_CHANGE';

const NAV_UNSELECTED = $r('sys.color.comp_focused_primary');
const BOTTOM_NORMAL_AVOID_AREA_VALUE = 1;
const BOTTOM_SPECIAL_AVOID_AREA_VALUE = 12;
const TOP_BAR_BLUR_RADIUS = 18;
const TOP_BAR_FRACTION_STOPS: [number, number][] = [[0, 0], [0.9, 0.08], [1, 0.4], [1, 1]];
const TOP_BAR_COLLAPSED_HEIGHT = 80;
const TOP_BAR_EXPANDED_HEIGHT = 144;

// 添加UP主卡片弹窗相关
const UP_FORM_PREFS = 'pili_form';
const KEY_FORM_MAP = 'up_card_map';

interface UpFormInfo {
  mid: string;
  name: string;
  avatar: string;
}

function topBarMaterial(interactive: boolean): uiMaterial.ImmersiveMaterial {
  return new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    interactive: interactive,
    lightEffect: {}
  });
}

/// Navbar 页签类型（与 Flutter NavigationBarType.values 顺序一致）→ 符号
function navTabSymbol(typeIndex: number): Resource {
  switch (typeIndex) {
    case 0:
      return $r('sys.symbol.house_fill');
    case 1:
      return $r('sys.symbol.discover_fill');
    case 2:
      return $r('sys.symbol.person_crop_circle_fill_1');
    default:
      return $r('sys.symbol.house_fill');
  }
}

/// Navbar 页签类型 → 文案（与 Flutter NavigationBarType.label 一致）
function navTabLabel(typeIndex: number): string {
  switch (typeIndex) {
    case 0:
      return '首页';
    case 1:
      return '动态';
    case 2:
      return '我的';
    default:
      return '';
  }
}

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext;
  @LocalStorageLink('viewId') viewId: string = "";
  @StorageLink('useNativeTabs') useNativeTabs: boolean = false;
  @StorageLink('shellBarsHidden') shellBarsHidden: boolean = false;
  @StorageLink('__scrollHidden') @Watch('onScrollHiddenChanged') shellBarsScrollHidden: boolean = false;
  @StorageLink('tabSelectedColor') navSelected: string = '#3367D6';
  @StorageLink('useNativeTopBar') useNativeTopBar: boolean = false;
  @StorageLink('topBarHidden') topBarHidden: boolean = false;
  @StorageLink('topBarCollapsed') topBarCollapsed: boolean = false;
  @StorageLink('homeHideTopBar') homeHideTopBar: boolean = false;
  @StorageLink('homeSearchText') homeSearchText: string = '';
  @StorageLink('homeUnreadCount') homeUnreadCount: string = '';
  @StorageLink('homeFaceUrl') homeFaceUrl: string = '';
  @StorageLink('homeTabs') homeTabs: string[] = [];
  @StorageLink('homeActiveTabIndex') @Watch('onHomeTabIndexChanged') homeActiveTabIndex: number = 0;
  /// 底部 Navbar 页签（NavigationBarType 索引，由 Flutter 按设置内
  /// Navbar 编辑同步；默认 首页/动态/我的）
  @StorageLink('navTabs') navTabs: number[] = [0, 1, 2];
  /// 动态页签角标模式（与 Flutter DynamicBadgeMode 一致：0=隐藏 1=红点 2=数字）
  @StorageLink('dynBadgeMode') dynBadgeMode: number = 0;
  /// 动态页签角标数量（由 Flutter 按未读动态数同步）
  @StorageLink('dynBadgeCount') dynBadgeCount: number = 0;
  /// 当前选中的底部 Navbar 页签索引（自定义 tabBar 需自行区分选中态）
  @State currentNavIndex: number = 0;
  @StorageLink('pendingUpCard') @Watch('onPendingUpCardChange') pendingUpCard: string = '';
  @StorageLink('showAddFormSheet') showAddFormSheet: boolean = false;
  @State upCardMid: string = '';
  @State upCardName: string = '';
  @State upCardAvatar: string = '';
  private upCardCompId: string = 'pili_up_card_add';
  @State statusBarHeight: number = 0;
  @State categoryCurrentIndex: number = 0;
  @State winWidth: number = 0;
  @State winHeight: number = 0;
  @State bottomAvoidAreaHeight: number = 0;
  private categoryController: TabsController = new TabsController();
  private controller: HdsTabsController = new HdsTabsController();
  private win: window.Window | null = null;
  private sizeCallback: ((size: window.Size) => void) | null = null;
  private rectCallback: ((opts: window.RectChangeOptions) => void) | null = null;

  onHomeTabIndexChanged(): void {
    if (this.homeActiveTabIndex >= 0 && this.homeActiveTabIndex < this.homeTabs.length) {
      this.categoryCurrentIndex = this.homeActiveTabIndex;
      this.categoryController.changeIndex(this.homeActiveTabIndex);
    }
  }

  onScrollHiddenChanged(): void {
    if (!this.useNativeTabs || this.shellBarsHidden) {
      return;
    }
    if (this.shellBarsScrollHidden) {
      this.controller.applyHideAnimation(HdsAnimationMode.SCROLL_ANIMATION);
    } else {
      this.controller.applyShowAnimation(HdsAnimationMode.SCROLL_ANIMATION);
    }
  }

  onPendingUpCardChange(): void {
    if (this.pendingUpCard.length === 0) {
      return;
    }
    try {
      const data: UpFormInfo = JSON.parse(this.pendingUpCard);
      this.upCardMid = data.mid ?? '';
      this.upCardName = data.name ?? '';
      this.upCardAvatar = data.avatar ?? '';
    } catch (e) {
      console.error(TAG, `parse pending up card failed: ${e}`);
    }
  }

  private async saveUpCardMap(formId: string | number): Promise<void> {
    try {
      const store = await preferences.getPreferences(this.context, UP_FORM_PREFS);
      const raw = store.getSync(KEY_FORM_MAP, '{}');
      let map: Record<string, Object> = {};
      try {
        map = JSON.parse(typeof raw === 'string' ? raw : '{}');
      } catch (e) {
      }
      const info: UpFormInfo = {
        mid: this.upCardMid, name: this.upCardName, avatar: this.upCardAvatar
      };
      map[String(formId)] = info;
      await store.put(KEY_FORM_MAP, JSON.stringify(map));
      await store.flush();
    } catch (e) {
      console.error(TAG, `save up card map failed: ${e}`);
    }
  }

  private applySize(widthPx: number, heightPx: number): void {
    this.winWidth = px2vp(widthPx);
    this.winHeight = px2vp(heightPx);
    // 同步到 AppStorage，供 HarmonyChannel.syncTopBarWithShell
    // 按窗口宽高比分流顶栏（收起/隐藏/显示）
    AppStorage.setOrCreate('winWidth', this.winWidth);
    AppStorage.setOrCreate('winHeight', this.winHeight);
  }

  aboutToAppear(): void {
    this.context.eventHub.on(EVENT_CHANGE_TAB, (index: number) => {
      this.currentNavIndex = index;
      this.controller.changeIndex(index);
    });

    window.getLastWindow(this.context).then((w: window.Window) => {
      this.win = w;
      let topAvoidArea = w.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      this.statusBarHeight = px2vp(topAvoidArea.topRect.height);
      w.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          this.statusBarHeight = px2vp(data.area.topRect.height);
        }
      });

      const rect = w.getWindowProperties().windowRect;
      this.applySize(rect.width, rect.height);
      this.sizeCallback = (size: window.Size) => {
        this.applySize(size.width, size.height);
      };
      w.on('windowSizeChange', this.sizeCallback);

      try {
        this.rectCallback = (opts: window.RectChangeOptions) => {
          this.applySize(opts.rect.width, opts.rect.height);
        };
        w.on('windowRectChange', this.rectCallback);
      } catch (err) {
        console.error(TAG, `windowRectChange listener failed: ${err}`);
      }

      let windowBottomAvoidArea = w.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      let uiContext = this.getUIContext();
      this.bottomAvoidAreaHeight = windowBottomAvoidArea.bottomRect.height === 0
        ? BOTTOM_SPECIAL_AVOID_AREA_VALUE
        : (uiContext.px2vp(windowBottomAvoidArea.bottomRect.height) + BOTTOM_NORMAL_AVOID_AREA_VALUE);

      w.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          this.bottomAvoidAreaHeight = data.area.bottomRect.height === 0
            ? BOTTOM_SPECIAL_AVOID_AREA_VALUE
            : (uiContext.px2vp(data.area.bottomRect.height) + BOTTOM_NORMAL_AVOID_AREA_VALUE);
        }
      });
    }).catch((err: Object) => {
      console.error(TAG, `getLastWindow failed: ${err}`);
    });
  }

  aboutToDisappear(): void {
    if (this.win !== null) {
      try {
        if (this.sizeCallback !== null) {
          this.win.off('windowSizeChange', this.sizeCallback);
        }
        if (this.rectCallback !== null) {
          this.win.off('windowRectChange', this.rectCallback);
        }
      } catch (err) {
        console.error(TAG, `off window listeners failed: ${err}`);
      }
      this.sizeCallback = null;
      this.rectCallback = null;
    }
  }

  @Builder
  categoryTabBuilder(index: number, name: string) {
    Text(name)
      .fontSize(15)
      .fontWeight(this.categoryCurrentIndex === index ? FontWeight.Bolder : FontWeight.Medium)
      .fontColor(this.categoryCurrentIndex === index ? this.navSelected : NAV_UNSELECTED)
      .height(28)
      .margin({
        left: index === 0 ? 8 : 3,
        right: index === this.homeTabs.length - 1 ? 8 : 3
      })
      .padding({ left: 15, right: 15 })
  }

  @Builder
  navTabBuilder(typeIndex: number, index: number) {
    Column({ space: 3 }) {
      if (typeIndex === 1 && this.dynBadgeCount > 0 && this.dynBadgeMode !== 0) {
        if (this.dynBadgeMode === 1) {
          // 红点角标
          Badge({
            value: '',
            position: BadgePosition.RightTop,
            style: { badgeSize: 8, badgeColor: this.navSelected, borderColor: $r('sys.color.comp_common_contrary') }
          }) {
            SymbolGlyph(navTabSymbol(typeIndex))
              .fontSize(22)
              .fontColor(
                [this.currentNavIndex === index ? this.navSelected : NAV_UNSELECTED, $r('sys.color.icon_tertiary')])
              .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_COLOR)
              .symbolEffect(new BounceSymbolEffect(), this.currentNavIndex === index)
          }
        } else {
          // 数字角标
          Badge({
            count: this.dynBadgeCount,
            position: BadgePosition.RightTop,
            style: {
              badgeSize: 13,
              fontSize: 8,
              fontWeight: FontWeight.Medium,
              badgeColor: this.navSelected,
              borderColor: $r('sys.color.comp_common_contrary'),
              color: $r('sys.color.comp_common_contrary')
            }
          }) {
            SymbolGlyph(navTabSymbol(typeIndex))
              .fontSize(22)
              .fontColor(
                [this.currentNavIndex === index ? this.navSelected : NAV_UNSELECTED, $r('sys.color.icon_tertiary')])
              .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_COLOR)
              .symbolEffect(new BounceSymbolEffect(), this.currentNavIndex === index)
          }
        }
      } else {
        SymbolGlyph(navTabSymbol(typeIndex))
          .fontSize(22)
          .fontColor(
            [this.currentNavIndex === index ? this.navSelected : NAV_UNSELECTED, $r('sys.color.icon_tertiary')])
          .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_COLOR)
          .symbolEffect(new BounceSymbolEffect(), this.currentNavIndex === index)
      }

      Text(navTabLabel(typeIndex))
        .fontSize(11)
        .fontWeight(this.currentNavIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentNavIndex === index ? this.navSelected : NAV_UNSELECTED)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  circleIconButton(icon: Resource, size: number, iconSize: number, onClick: () => void) {
    Stack() {
      SymbolGlyph(icon)
        .fontSize(iconSize)
        .width(iconSize)
        .height(iconSize)
        .fontColor([this.navSelected])
        .align(Alignment.Center)
    }
    .width(size)
    .height(size)
    .borderRadius(size / 2)
    .systemMaterial(topBarMaterial(true))
    .onClick(onClick)
  }

  @Builder
  msgButton() {
    Stack() {
      this.circleIconButton($r('sys.symbol.bell'), 44, 22, () => {
        this.context.eventHub.emit(EVENT_TOP_MSG);
      })
      if (this.homeUnreadCount !== '') {
        Text(this.homeUnreadCount)
          .fontSize(9)
          .fontColor(Color.White)
          .padding({
            left: 5,
            right: 5,
            top: 1,
            bottom: 1
          })
          .backgroundColor(this.navSelected)
          .borderRadius(8)
          .offset({ x: 6, y: -8 })
      }
    }
    .width(44)
    .height(44)
  }

  @Builder
  avatarButton() {
    if (this.homeFaceUrl !== '') {
      Image(this.homeFaceUrl)
        .width(41)
        .height(41)
        .borderRadius(20.5)
        .onClick(() => {
          this.context.eventHub.emit(EVENT_TOP_MINE);
        })
        .systemMaterial(topBarMaterial(true))
    } else {
      this.circleIconButton($r('sys.symbol.person_crop_circle_fill'), 44, 26, () => {
        this.context.eventHub.emit(EVENT_TOP_MINE);
      })
    }
  }

  @Builder
  addFormMenuBuilder() {
    Menu() {
      AddFormMenuItem(
        {
          bundleName: 'com.example.piliplus',
          abilityName: 'EntryFormAbility',
          parameters: {
            'ohos.extra.param.key.form_dimension': 1,
            'ohos.extra.param.key.form_name': 'up_card',
            'ohos.extra.param.key.module_name': 'entry',
          },
        },
        this.upCardCompId,
        {
          formBindingData: formBindingData.createFormBindingData({
            mid: this.upCardMid,
            name: this.upCardName,
            avatar: this.upCardAvatar,
          }),
          callback: (error, formId) => {
            if (error?.code === 0) {
              this.saveUpCardMap(formId);
              promptAction.showToast({ message: '已添加UP主卡片到桌面' });
            } else {
              promptAction.showToast({
                message: `添加失败：${error?.message ?? error?.code ?? '未知错误'}`,
              });
            }
            this.showAddFormSheet = false;
          },
        },
      )
    }
  }

  @Builder
  addFormSheet() {
    Column({ space: 20 }) {
      Row({ space: 12 }) {
        Image(this.upCardAvatar)
          .width(48)
          .height(48)
          .borderRadius(24)
          .objectFit(ImageFit.Cover)
          .alt($r('app.media.icon_startwindow'))
        Column({ space: 4 }) {
          Text(this.upCardName)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('将UP主添加到桌面')
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .alignItems(VerticalAlign.Center)

      Button('添加到桌面')
        .id(this.upCardCompId)
        .bindMenu(this.addFormMenuBuilder)
        .width('80%')
        .height(42)
        .fontSize(16)
    }
    .width('100%')
    .padding({ top: 20, bottom: 24, left: 24, right: 24 })
  }

  @Builder
  homeTopBar() {
    RelativeContainer() {
      //渐变模糊底层
      Column() {
      }
      .constraintSize({ maxHeight: TOP_BAR_EXPANDED_HEIGHT })
      .linearGradientBlur(TOP_BAR_BLUR_RADIUS, {
        fractionStops: TOP_BAR_FRACTION_STOPS,
        direction: GradientDirection.Top
      })
      .alignRules({
        top: { anchor: 'topBarContent', align: VerticalAlign.Top },
        bottom: { anchor: 'topBarContent', align: VerticalAlign.Bottom },
        left: { anchor: 'topBarContent', align: HorizontalAlign.Start },
        right: { anchor: 'topBarContent', align: HorizontalAlign.End }
      })
      .id('topBarBg')
      .hitTestBehavior(HitTestMode.Transparent)

      Column() {
        Row({ space: 8 }) {
          Search({ value: this.homeSearchText, placeholder: '搜索' })
            .cancelButton({ style: CancelButtonStyle.INVISIBLE })
            .focusable(false)
            .enableKeyboardOnFocus(false)
            .searchIcon(new SymbolGlyphModifier($r('sys.symbol.magnifyingglass'))
              .fontColor([this.navSelected]).fontSize(16))
            .placeholderColor($r('app.color.placeholder_text'))
            .placeholderFont({ size: 16, weight: 600 })
            .fontColor($r('app.color.placeholder_text'))
            .textFont({ size: 16, weight: 600 })
            .backgroundColor(Color.Transparent)
            .borderRadius(22)
            .layoutWeight(1)
            .height(44)
            .systemMaterial(topBarMaterial(true))
            .onClick(() => {
              this.context.eventHub.emit(EVENT_TOP_SEARCH);
            })
          this.msgButton()
          this.avatarButton()
        }
        .width('100%')
        .padding({
          left: 14,
          right: 14,
        })
        .margin({
          top: this.homeHideTopBar && this.topBarCollapsed ? 0 : 5,
          bottom: this.homeHideTopBar && this.topBarCollapsed ? -5 : 5
        })
        .height(this.homeHideTopBar && this.topBarCollapsed ? 0 : 44)
        .opacity(this.homeHideTopBar && this.topBarCollapsed ? 0 : 1)
        .animation({ duration: 220, curve: Curve.EaseInOut })

        if (this.homeTabs.length > 1) {
          Tabs({ barPosition: BarPosition.Start, controller: this.categoryController }) {
            ForEach(this.homeTabs, (tab: string, index: number) => {
              TabContent() { // empty
              }
              .tabBar(this.categoryTabBuilder(index, tab))
            }, (tab: string, index: number) => index + '_' + tab)
          }
          .barMode(BarMode.Scrollable)
          .fadingEdge(false)
          .scrollable(false)
          .width('100%')
          .height(32)
          .onTabBarClick((index: number) => {
            this.context.eventHub.emit(EVENT_HOME_TAB_CHANGE, index);
            this.categoryCurrentIndex = index;
          })
        }
      }
      .width('100%')
      .padding({ top: this.statusBarHeight})
      .id('topBarContent')
      .hitTestBehavior(HitTestMode.Default)
    }
    .height(this.homeHideTopBar && this.topBarCollapsed
      ? TOP_BAR_COLLAPSED_HEIGHT
      : TOP_BAR_EXPANDED_HEIGHT)
    .animation({ duration: 220, curve: Curve.EaseInOut })
    .width('100%')
    .hitTestBehavior(HitTestMode.Default)
    .visibility(this.topBarHidden ? Visibility.None : Visibility.Visible)
  }

  @Builder
  hdsMainTabs() {
    HdsTabs({ controller: this.controller }) {
      ForEach(this.navTabs, (typeIndex: number, index: number) => {
        TabContent() { // empty
        }
        .tabBar(this.navTabBuilder(typeIndex, index))
      }, (typeIndex: number, index: number) => index + '_' + typeIndex)
    }
    .onTabBarClick((index: number) => {
      this.currentNavIndex = index;
      this.context.eventHub.emit(EVENT_TAB_SWITCH, index);
    })
    .scrollable(false)
    .barOverlap(true)
    .barPosition(BarPosition.End)
    .vertical(false)
    .barFloatingStyle({
      barBottomMargin: this.bottomAvoidAreaHeight,
      adaptToHandedness: true,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
      }
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.Bottom }) {
        FlutterPage({ viewId: this.viewId })
          .width('100%')
          .height('100%')
        if (this.useNativeTabs && deviceInfo.sdkApiVersion >= 23) {
          Column() {
            this.hdsMainTabs()
          }
          .hitTestBehavior(HitTestMode.Transparent)
          .width('100%')
          .height('100%')
          .visibility(this.navTabs.length <= 1 || this.shellBarsHidden
            ? Visibility.None
            : Visibility.Visible)
        }
      }
      .width('100%')
      .height('100%')

      if (this.useNativeTopBar && deviceInfo.sdkApiVersion >= 26) {
        this.homeTopBar()
      }
    }
    .width(this.winWidth > 0 ? this.winWidth : '100%')
    .height(this.winHeight > 0 ? this.winHeight : '100%')
    .bindSheet($$this.showAddFormSheet, this.addFormSheet(), {
      height: 220,
      dragBar: true,
    })
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}
