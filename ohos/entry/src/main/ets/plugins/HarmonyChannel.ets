import { common, wantAgent, WantAgent } from "@kit.AbilityKit";
import { BusinessError, deviceInfo } from "@kit.BasicServicesKit";
import { http } from "@kit.NetworkKit";
import { util } from "@kit.ArkTS";
import { fileIo } from "@kit.CoreFileKit";
import { formProvider } from "@kit.FormKit";
import AbilityConstant from "@ohos.app.ability.AbilityConstant";
import Want from "@ohos.app.ability.Want";
import ConfigurationConstant from "@ohos.app.ability.ConfigurationConstant";
import { backgroundTaskManager } from "@kit.BackgroundTasksKit";
import window from "@ohos.window";
import {
  Any,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodChannel,
  MethodResult,
} from "@ohos/flutter_ohos";

// import display from "@ohos.display";

const colorModeMap: Record<string, ConfigurationConstant.ColorMode> = {
  "light": ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT,
  "dark": ConfigurationConstant.ColorMode.COLOR_MODE_DARK,
  "system": ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET,
};

export default class HarmonyChannel implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private lastWindow: window.Window | null = null;
  private bgTaskPromise: Promise<void> = Promise.resolve();
  private isBackgroundTaskRunning: boolean = false;
  private bgTaskWanted: boolean = false;
  /// 当前底部页签是否为首页（由 Flutter 同步）。
  /// 用于 dialog 隐藏/显示顶栏时的多级分支判断。
  private topBarIsHome: boolean = false;
  /// 跨设备接续：对端 onCreate/onNewWant 收到的接续数据暂存于此，
  /// 由 Dart 侧就绪后主动拉取（getPendingContinuation），规避冷启动时
  /// Dart handler 尚未注册导致推送丢失的问题。
  private pendingContinuation: string | null = null;

  getUniqueClassName(): string {
    return "HarmonyChannel";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "harmonyChannel");
    this.channel.setMethodCallHandler(this);
    // // 监听画面方向
    // display.on('change', () => {
    //   // 获取当前旋转角度
    //   let rotation = display.getDefaultDisplaySync().rotation;
    //   this.channel!.invokeMethod('onRotationChange', { 'rotation': rotation })
    // })
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
  }

  public getChannel(): MethodChannel | null {
    return this.channel;
  }


  /**
   * 全屏/退出全屏时只切换系统栏显隐，不改窗口布局。
   * 不要调用 setWindowLayoutFullScreen：它会改变 surface 尺寸，
   * 导致 Flutter 视口变化，旋转进出全屏时画面跳动。
   * 窗口布局保持主流程（main.dart 的 edgeToEdge）设置的普通布局。
   */
  async setFullScreenBars(fullscreen: boolean) {
    this.lastWindow ??= await window.getLastWindow(getContext());
    await this.lastWindow.setSpecificSystemBarEnabled("status", !fullscreen, false);
    await this.lastWindow.setSpecificSystemBarEnabled("navigation", !fullscreen, false);
    await this.lastWindow.setSpecificSystemBarEnabled("navigationIndicator", !fullscreen, false);
  }

  async setWindowOrientation(orientation: number) {
    this.lastWindow ??= await window.getLastWindow(getContext());
    await this.lastWindow.setPreferredOrientation(orientation);
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case "setFullScreenBars": {
        const fullscreen: boolean = call.argument("fullscreen") ?? false;
        await this.setFullScreenBars(fullscreen);
        result.success(true);
        break;
      }
      case "setWindowOrientation": {
        const orientation: number = call.argument("orientation") ?? 0;
        await this.setWindowOrientation(orientation);
        result.success(true);
        break;
      }
      case "setMiniWindowLandscape":
        const landscape: boolean = call.argument("landscape") ?? false;
        await this.setMiniWindowLandscape(landscape);
        result.success(true);
        break;
      case "setDecorButtonDark": {
        const dark: boolean = call.argument("dark") ?? false;
        await this.setDecorButtonDark(dark);
        result.success(true);
        break;
      }
      case "getPendingContinuation": {
        const data = this.pendingContinuation;
        this.pendingContinuation = null;
        result.success(data);
        break;
      }
      case "setContinuationActive": {
        const active: boolean = call.argument("active") ?? false;
        this.setMissionContinueState(active);
        result.success(true);
        break;
      }
      case "getSystemFontWeightScale": {
        result.success(true);
        break;
      }
      case "setShellBars": {
        if (deviceInfo.sdkApiVersion < 23) {
          result.success(true);
          break;
        }
        const useNativeTabs: boolean = call.argument('useNativeTabs') ?? false;
        console.log(`is use native tabs: ${useNativeTabs}`);
        AppStorage.setOrCreate('useNativeTabs', useNativeTabs);
        result.success(true);
        break;
      }
      case "setNavBarConfig": {
        if (deviceInfo.sdkApiVersion < 23) {
          result.success(true);
          break;
        }
        // 底部 Navbar 页签（NavigationBarType 索引），与设置内 Navbar 编辑一致
        const tabs: number[] = call.argument('tabs') ?? [0, 1, 2];
        AppStorage.setOrCreate('navTabs', tabs);
        result.success(true);
        break;
      }
      case "setDynamicBadge": {
        if (deviceInfo.sdkApiVersion < 23) {
          result.success(true);
          break;
        }
        // 动态页签角标（mode 与 Flutter DynamicBadgeMode 一致：0=隐藏 1=红点 2=数字）
        const count: number = call.argument('count') ?? 0;
        const mode: number = call.argument('mode') ?? 0;
        AppStorage.setOrCreate('dynBadgeCount', count);
        AppStorage.setOrCreate('dynBadgeMode', mode);
        result.success(true);
        break;
      }
      case "startBackgroundTask": {
        this.startBackgroundTaskInner();
        result.success(true);
        break;
      }
      case "stopBackgroundTask": {
        this.stopBackgroundTaskInner();
        result.success(true);
        break;
      }
      case "setShellBarsHidden": {
        if (deviceInfo.sdkApiVersion < 23) {
          result.success(true);
          break;
        }
        const hidden: boolean = call.argument('hidden') ?? false;
        const force: boolean = call.argument('force') ?? false;
        AppStorage.setOrCreate('shellBarsHidden', hidden);
        // 沉浸光感顶栏与底栏共用此显隐信号：底栏直接隐藏，
        // 顶栏按「是否首页 + 窗口宽高比」在 ArkTS 侧多级分支。
        this.syncTopBarVisibility(hidden,force);
        result.success(true);
        break;
      }
      case "setTopBarIsHome": {
        if (deviceInfo.sdkApiVersion < 23) {
          result.success(true);
          break;
        }
        this.topBarIsHome = call.argument('isHome') ?? false;
        console.log(`is top bar home: ${this.topBarIsHome}`);
        result.success(true);
        break;
      }
      case "setShellBarsScrollHidden": {
        if (deviceInfo.sdkApiVersion < 23) {
          result.success(true);
          break;
        }
        const hidden: boolean = call.argument('hidden') ?? false;
        if (AppStorage.get('__scrollHidden') != hidden) {
          AppStorage.setOrCreate('__scrollHidden', hidden);
        }
        result.success(true);
        break;
      }
      case "changeTabIndex": {
        if (deviceInfo.sdkApiVersion < 23) {
          result.success(true);
          break;
        }
        const index: number = call.argument('index') ?? 0;
        this.changeTabIndex(index);
        result.success(true);
        break;
      }
      case "setTabSelectedColor": {
        if (deviceInfo.sdkApiVersion < 23) {
          result.success(true);
          break;
        }
        const color: string = call.argument('color') ?? '#3367D6';
        const subColor: string = '#88'+color.substring(1);
        AppStorage.setOrCreate('tabSelectedColor', color);
        AppStorage.setOrCreate('tabSelectedSubColor', subColor);
        result.success(true);
        break;
      }
      case "setShellTopBar": {
        if (deviceInfo.sdkApiVersion < 26) {
          result.success(true);
          break;
        }
        const useNativeTopBar: boolean = call.argument('useNativeTopBar') ?? false;
        AppStorage.setOrCreate('useNativeTopBar', useNativeTopBar);
        result.success(true);
        break;
      }
      case "setHomeTopBarData": {
        const tabs: string[] = call.argument('tabs') ?? [];
        const hideTopBar: boolean = call.argument('hideTopBar') ?? false;
        const activeIndex: number = call.argument('activeIndex') ?? 0;
        AppStorage.setOrCreate('homeTabs', tabs);
        AppStorage.setOrCreate('homeHideTopBar', hideTopBar);
        AppStorage.setOrCreate('homeActiveTabIndex', activeIndex);
        result.success(true);
        break;
      }
      case "setHomeSearchText": {
        const text: string = call.argument('text') ?? '';
        AppStorage.setOrCreate('homeSearchText', text);
        result.success(true);
        break;
      }
      case "setHomeUnreadCount": {
        const count: string = call.argument('count') ?? '';
        AppStorage.setOrCreate('homeUnreadCount', count);
        result.success(true);
        break;
      }
      case "setHomeFaceUrl": {
        const url: string = call.argument('url') ?? '';
        AppStorage.setOrCreate('homeFaceUrl', url);
        result.success(true);
        break;
      }
      case "setHomeTabIndex": {
        const index: number = call.argument('index') ?? 0;
        AppStorage.setOrCreate('homeActiveTabIndex', index);
        result.success(true);
        break;
      }
      case "setTopBarCollapsed": {
        const collapsed: boolean = call.argument('collapsed') ?? false;
        AppStorage.setOrCreate('topBarCollapsed', collapsed);
        result.success(true);
        break;
      }
      case "setTopBarHidden": {
        const hidden: boolean = call.argument('hidden') ?? false;
        AppStorage.setOrCreate('topBarHidden', hidden);
        result.success(true);
        break;
      }
      case "setSystemColorMode": {
        const colorMode: string = call.argument('colorMode') ?? '';
        this.setColorMode(colorMode);
        result.success(true);
        break;
      }
      // case 'setWindowLayoutFullScreen': {
      //   this.lastWindow ??= await window.getLastWindow(getContext())
      //   this.lastWindow.setWindowLayoutFullScreen(call.argument('fullScreen'));
      //   result.success(true);
      //   break;
      // }
      case "addUpToDesktop": {
        await this.addUpToDesktop(call);
        result.success(true);
        break;
      }
      default:
        result.notImplemented();
        break;
    }
  }

  // 设置应用上下文的深浅色模式。
  private setColorMode(colorMode: string): void {
    try {
      const context = getContext() as common.ApplicationContext;
      context.setColorMode(colorModeMap[colorMode]);
      console.log('HarmonyChannel', `set color mode: ${colorMode}`);
    } catch (err) {
      console.error("HarmonyChannel", `get application context failed: ${err}`);
    }
  }

  /**
   * 添加UP主卡片到桌面：先下载头像转base64并保存待添加的UP数据
   * （onAddForm 时同步读取绑定卡片），再拉起系统卡片管理页让用户添加。
   */
  private async addUpToDesktop(call: MethodCall): Promise<void> {
    const mid = String(call.argument("mid") ?? "");
    const name = String(call.argument("name") ?? "");
    const avatar = String(call.argument("avatar") ?? "");
    const topPhoto = String(call.argument("topPhoto") ?? "");
    if (mid.length === 0) {
      return;
    }
    const avatarData = await this.downloadAvatarBase64(avatar);
    const topPhotoData = await this.downloadAvatarBase64(topPhoto);
    // 写沙箱文件（比 Preferences 可靠：onAddForm 同步读文件，无缓存/跨进程问题）
    try {
      const context = getContext() as common.Context;
      const file = fileIo.openSync(
        `${context.filesDir}/pending_up_card.json`,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC
      );
      fileIo.writeSync(file.fd, JSON.stringify({
        mid: mid, name: name, avatar: avatarData, topPhoto: topPhotoData
      }));
      fileIo.closeSync(file);
    } catch (e) {
      console.error("HarmonyChannel", `save pending up failed: ${e}`);
    }
    try {
      const context = getContext() as common.UIAbilityContext;
      formProvider.openFormManager({
        bundleName: context.abilityInfo.bundleName,
        abilityName: "EntryFormAbility",
        parameters: {
          'ohos.extra.param.key.form_dimension': 1,
          'ohos.extra.param.key.form_name': 'up_card',
          'ohos.extra.param.key.module_name': 'entry',
        },
      });
    } catch (e) {
      console.error("HarmonyChannel", `openFormManager failed: ${e}`);
    }
  }

  /** 下载头像并以 base64 存储，供卡片/引导页直接显示 */
  private async downloadAvatarBase64(url: string): Promise<string> {
    if (url.length === 0) {
      return '';
    }
    let httpRequest: http.HttpRequest | null = null;
    try {
      httpRequest = http.createHttp();
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 15000,
        readTimeout: 15000,
      });
      if (resp.responseCode !== 200) {
        return '';
      }
      const result = resp.result;
      let bytes: ArrayBuffer;
      if (result instanceof ArrayBuffer) {
        bytes = result;
      } else if (result instanceof Uint8Array) {
        bytes = result.buffer as ArrayBuffer;
      } else {
        return '';
      }
      if (bytes.byteLength === 0) {
        return '';
      }
      const mime = url.toLowerCase().includes('.webp') ? 'image/webp' : 'image/jpeg';
      const base64 = new util.Base64Helper().encodeToStringSync(new Uint8Array(bytes));
      return `data:${mime};base64,${base64}`;
    } catch (e) {
      console.error("HarmonyChannel", `download avatar failed: ${e}`);
      return '';
    } finally {
      httpRequest?.destroy();
    }
  }

  private startBackgroundTaskInner(): void {
    this.enqueueBgTask(true);
  }

  private stopBackgroundTaskInner(): void {
    this.enqueueBgTask(false);
  }

  /**
   * Promise 链式队列：将所有 start/stop 请求排队执行，
   * 只根据最终期望状态 (bgTaskWanted) 决定实际操作，消除竞态条件。
   */
  private enqueueBgTask(wanted: boolean): void {
    this.bgTaskWanted = wanted;
    this.bgTaskPromise = this.bgTaskPromise.then(async (): Promise<void> => {
      if (this.bgTaskWanted) {
        // 期望启动；若实际未运行则执行启动
        if (this.isBackgroundTaskRunning) {
          return;
        }
        try {
          const context: common.UIAbilityContext = getContext() as common.UIAbilityContext;
          const wantAgentInfo: wantAgent.WantAgentInfo = {
            wants: [
              {
                bundleName: context.abilityInfo.bundleName,
                abilityName: context.abilityInfo.name,
              } as Want,
            ],
            actionType: wantAgent.OperationType.START_ABILITY,
            requestCode: 0,
            actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG] as Array<wantAgent.WantAgentFlags>,
          };
          const wantAgentObj: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);
          const list: Array<string> = ["dataTransfer"];
          await backgroundTaskManager.startBackgroundRunning(
            context, list, wantAgentObj,
          );
          this.isBackgroundTaskRunning = true;
          console.info("HarmonyChannel", "Background task started (dataTransfer)");
        } catch (error) {
          console.error("HarmonyChannel",
            `startBackgroundTask failed, code: ${(error as BusinessError).code}, msg: ${(error as
              BusinessError).message}`);
        }
      } else {
        // 期望停止；若实际在运行则执行停止
        if (!this.isBackgroundTaskRunning) {
          return;
        }
        try {
          await backgroundTaskManager.stopBackgroundRunning(getContext());
          this.isBackgroundTaskRunning = false;
          console.info("HarmonyChannel", "Background task stopped");
        } catch (error) {
          console.error("HarmonyChannel",
            `stopBackgroundTask failed, code: ${(error as BusinessError).code}, msg: ${(error as
              BusinessError).message}`);
        }
      }
    });
  }

  /**
   * 沉浸光感顶栏与底部导航栏共用 dialog 隐藏/显示信号时的多级分流。
   *
   * 宽高比 = 窗口宽 / 窗口高（Index.ets 已随窗口尺寸变化维护 winWidth/winHeight）：
   * - 当前不是首页：不处理（顶栏仅首页显示）
   * - 隐藏 + 宽高比 < 9/16（竖长屏）：不处理
   * - 隐藏 + 宽高比 9/16 ~ 1:1：改为「收起」顶栏
   * - 隐藏 + 宽高比 ≥ 1:1（正方/横屏）：隐藏顶栏
   * - 显示 + 宽高比 9/16 ~ 1:1：放下 + 显示顶栏
   * - 显示 + 宽高比 9/16 ~ 1:1 以外：仅显示顶栏
   */
  private syncTopBarVisibility(hidden: boolean, force: boolean): void {
    // 顶栏未启用或不处于首页时不处理
    if (AppStorage.get('useNativeTopBar') !== true || !this.topBarIsHome) {
      return;
    }
    const width = AppStorage.get('winWidth') as number ?? 0;
    const height = AppStorage.get('winHeight') as number ?? 0;
    if (width <= 0 || height <= 0) {
      return;
    } // 尚未拿到窗口尺寸
    const aspect = width / height;
    const portrait = aspect < 1.0;
    const tall = aspect < 9 / 16; // 竖长屏
    if (force) {
      AppStorage.setOrCreate('topBarHidden', hidden);
      return;
    }
    if (hidden) {
      if (tall) {
        return;
      } // 竖长屏不处理
      if (portrait) {
        AppStorage.setOrCreate('topBarCollapsed', true); // 9/16 ~ 1:1：收起
      } else {
        AppStorage.setOrCreate('topBarHidden', true); // ≥ 1:1：隐藏
      }
    } else {
      AppStorage.setOrCreate('topBarHidden', false);
    }
  }


  public changeTabIndex(index: number): void {
    const context = getContext() as common.UIAbilityContext;
    context.eventHub.emit('EVENT_CHANGE_TAB', index);
  }

  public onFloatingWindowChange(isFloatingWindow: boolean) {
    this.channel?.invokeMethod("onFloatingWindowChange", { isFloatingWindow: isFloatingWindow });
  }

  public onWindowModeChange(isWindowMode: boolean) {
    this.channel?.invokeMethod("onWindowModeChange", { isWindowMode: isWindowMode });
  }

  /**
   * 源端 onContinue 时向 Dart 拉取当前播放状态（JSON 字符串），
   * 无播放或超时返回 null。onContinue 有系统时限，超时兜底避免卡死接续流程。
   */
  public getContinuationState(): Promise<string | null> {
    if (this.channel == null) {
      return Promise.resolve(null);
    }
    return new Promise<string | null>((resolve) => {
      const timer = setTimeout(() => resolve(null), 1500);
      const callback: MethodResult = {
        success: (result: Any) => {
          clearTimeout(timer);
          resolve(typeof result === "string" ? result : null);
        },
        error: (_code: string, _msg: string, _details: Any) => {
          clearTimeout(timer);
          resolve(null);
        },
        notImplemented: () => {
          clearTimeout(timer);
          resolve(null);
        },
      };
      this.channel!.invokeMethod("getContinuationState", null, callback);
    });
  }

  /**
   * 对端收到接续数据：暂存并通知 Dart。冷启动时 Dart 尚未就绪，
   * 通知会丢失，但 Dart 首帧后会主动拉取暂存数据。
   */
  public setPendingContinuation(data: string) {
    this.pendingContinuation = data;
    this.channel?.invokeMethod("onContinuationRestore", null);
  }

  /**
   * 动态控制本应用在对端设备是否显示为“可接续”：仅播放器持有视频时激活，
   * 避免用户在无播放时发起接续而失败。
   */
  private setMissionContinueState(active: boolean) {
    const context = getContext() as common.UIAbilityContext;
    const state = active
      ? AbilityConstant.ContinueState.ACTIVE
      : AbilityConstant.ContinueState.INACTIVE;
    context.setMissionContinueState(state).catch((err: Object) => {
      console.error("HarmonyChannel", `setMissionContinueState failed: ${err}`);
    });
  }

  private async setMiniWindowLandscape(landscape: boolean) {
    this.lastWindow ??= await window.getLastWindow(getContext());
    if (landscape) {
      this.lastWindow.enableLandscapeMultiWindow();
    } else {
      this.lastWindow.disableLandscapeMultiWindow();
    }
  }

  /**
   * 自由多窗装饰栏按钮颜色：dark=true 时按深色模式渲染（浅色按钮，适配
   * 深色内容顶部），false 恢复跟随系统颜色模式。仅装饰栏可见（自由窗口）
   * 时有视觉效果，其余窗口形态下为无害空操作。
   */
  private async setDecorButtonDark(dark: boolean) {
    this.lastWindow ??= await window.getLastWindow(getContext());
    try {
      this.lastWindow.setDecorButtonStyle({
        colorMode: dark
          ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK
          : ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET,
      });
    } catch (err) {
      console.error("HarmonyChannel", `setDecorButtonStyle failed: ${err}`);
    }
  }
}
