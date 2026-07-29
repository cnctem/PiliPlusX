
import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import { FlutterPage } from '@ohos/flutter_ohos';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HdsAnimationMode, hdsMaterial, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { Available } from '@kit.BasicServicesKit';

let storage = LocalStorage.getShared();
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS';
const TAG = 'Index';

// 底栏相关事件，由 EntryAbility 的 eventHub 监听
const EVENT_TAB_HOME = 'EVENT_TAB_HOME';
const EVENT_TAB_DYNAMICS = 'EVENT_TAB_DYNAMICS';
const EVENT_TAB_MINE = 'EVENT_TAB_MINE';
const EVENT_CHANGE_TAB = 'EVENT_CHANGE_TAB';

const NAV_UNSELECTED = $r('sys.color.comp_focused_primary');

const BOTTOM_NORMAL_AVOID_AREA_VALUE = 1;
const BOTTOM_SPECIAL_AVOID_AREA_VALUE = 12;

function tabSymbol(symbol: Resource, color: ResourceColor): SymbolGlyphModifier {
  return new SymbolGlyphModifier(symbol)
    .fontSize(22)
    .fontColor([color]);
}

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @LocalStorageLink('viewId') viewId: string = "";
  @StorageLink('useNativeTabs') useNativeTabs: boolean = false;
  // 页面/弹窗切换时的即时显隐（无动画，由 Visibility 控制）
  @StorageLink('shellBarsHidden') shellBarsHidden: boolean = false;
  // 滚动时的动画显隐（有动画，由 @Watch 驱动）
  @StorageLink('__scrollHidden') @Watch('onScrollHiddenChanged') shellBarsScrollHidden: boolean = false;
  // 底栏选中色（由 Flutter 侧主题色同步）
  @StorageLink('tabSelectedColor') navSelected: string = '#3367D6';

  // 引擎的视口尺寸只跟随 XComponent surface 的 OnSurfaceChanged，而系统
  // 程序化改窗口（如全景多窗全屏走的 enableLandscapeMultiWindow）不会触发
  // ArkUI 重布局，surface 停在旧尺寸，Flutter 按旧窗口尺寸布局，右/下出现
  // 大片白区（手动拖动窗口会强制重布局所以能恢复）。这里监听窗口尺寸并把
  // 它显式绑定到根容器，用状态变化驱动重布局，让 surface 跟上窗口。
  @State winWidth: number = 0;
  @State winHeight: number = 0;
  private win: window.Window | null = null;
  private sizeCallback: ((size: window.Size) => void) | null = null;
  private rectCallback: ((opts: window.RectChangeOptions) => void) | null = null;
  // HdsTabs的controller
  private controller: HdsTabsController = new HdsTabsController();

  // 当前底部避让区变量
  @State bottomAvoidAreaHeight: number = 0;

  private applySize(widthPx: number, heightPx: number): void {
    this.winWidth = px2vp(widthPx);
    this.winHeight = px2vp(heightPx);
  }

  aboutToAppear(): void {
    // Flutter 发起的页签切换 → 同步 ArkTS HdsTabs 高亮
    this.context.eventHub.on(EVENT_CHANGE_TAB, (index: number) => {
      this.controller.changeIndex(index);
    });

    window.getLastWindow(this.context).then((w: window.Window) => {
      this.win = w;
      const rect = w.getWindowProperties().windowRect;
      this.applySize(rect.width, rect.height);
      this.sizeCallback = (size: window.Size) => {
        this.applySize(size.width, size.height);
      };
      w.on('windowSizeChange', this.sizeCallback);
      // windowSizeChange 对部分程序化窗口调整不回调，windowRectChange
      // (@since 12) 覆盖移动/缩放全部来源，双保险。
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
      // 如果下方有避让区，则只需添加正常情况下的避让offset，反而添加特殊情况下的避让offset，保证悬浮窗模式下的底栏可读性
      this.bottomAvoidAreaHeight = windowBottomAvoidArea.bottomRect.height === 0 ? BOTTOM_SPECIAL_AVOID_AREA_VALUE : (uiContext.px2vp(windowBottomAvoidArea.bottomRect.height) + BOTTOM_NORMAL_AVOID_AREA_VALUE);

      w.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          // 如果下方有避让区，则只需添加正常情况下的避让offset，反而添加特殊情况下的避让offset，保证悬浮窗模式下的底栏可读性
          this.bottomAvoidAreaHeight = data.area.bottomRect.height === 0 ? BOTTOM_SPECIAL_AVOID_AREA_VALUE : (uiContext.px2vp(data.area.bottomRect.height) + BOTTOM_NORMAL_AVOID_AREA_VALUE);
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

  // 滚动时的动画显隐回调
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

  @Builder
  emptyTabContent() {
    Column()
      .width('100%')
      .height('100%')
  }

  @Builder
  hdsMainTabs() {
    HdsTabs({ controller: this.controller }) {
      TabContent() {
        this.emptyTabContent();
      }
      .tabBar(new BottomTabBarStyle({
        normal: tabSymbol($r('sys.symbol.house_fill'), NAV_UNSELECTED),
        selected: tabSymbol($r('sys.symbol.house_fill'), this.navSelected)
      }, '首页').labelStyle({
        selectedColor: this.navSelected,
        unselectedColor: NAV_UNSELECTED
      }))

      TabContent() {
        this.emptyTabContent();
      }
      .tabBar(new BottomTabBarStyle({
        normal: tabSymbol($r('sys.symbol.discover_fill'), NAV_UNSELECTED),
        selected: tabSymbol($r('sys.symbol.discover_fill'), this.navSelected)
      }, '动态').labelStyle({
        selectedColor: this.navSelected,
        unselectedColor: NAV_UNSELECTED
      }))

      TabContent() {
        this.emptyTabContent();
      }
      .tabBar(new BottomTabBarStyle({
        normal: tabSymbol($r('sys.symbol.person_crop_circle_fill_1'), NAV_UNSELECTED),
        selected: tabSymbol($r('sys.symbol.person_crop_circle_fill_1'), this.navSelected)
      }, '我的').labelStyle({
        selectedColor: this.navSelected,
        unselectedColor: NAV_UNSELECTED
      }))
    }
    .onChange((index: number) => {
      // 通知 EntryAbility 切换 Flutter 页面
      if (index === 0) {
        this.context.eventHub.emit(EVENT_TAB_HOME);
      } else if (index === 1) {
        this.context.eventHub.emit(EVENT_TAB_DYNAMICS);
      } else if (index === 2) {
        this.context.eventHub.emit(EVENT_TAB_MINE);
      }
    })
    .scrollable(false) // tab不可滑动
    .barOverlap(true)
    .barPosition(BarPosition.End)
    .vertical(false)
    .barFloatingStyle({
      barBottomMargin: this.bottomAvoidAreaHeight,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
      }
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      FlutterPage({ viewId: this.viewId })
        .width('100%')
        .height('100%')
      if (this.useNativeTabs) {
        Column() {
          this.hdsMainTabs()
        }
        .hitTestBehavior(HitTestMode.Transparent) // 透传触控操作，防止影响flutter层触摸
        .width('100%')
        .height('100%')
        // 页面/弹窗切换时即时隐藏，无动画
        .visibility(this.shellBarsHidden ? Visibility.None : Visibility.Visible)
      }
    }
    .width(this.winWidth > 0 ? this.winWidth : '100%')
    .height(this.winHeight > 0 ? this.winHeight : '100%')
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}
