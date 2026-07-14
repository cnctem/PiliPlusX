
import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import { FlutterPage } from '@ohos/flutter_ohos'

let storage = LocalStorage.getShared()
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'
const TAG = 'Index'

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @LocalStorageLink('viewId') viewId: string = "";
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

  private applySize(widthPx: number, heightPx: number): void {
    this.winWidth = px2vp(widthPx);
    this.winHeight = px2vp(heightPx);
  }

  aboutToAppear(): void {
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

  build() {
    Column() {
      FlutterPage({ viewId: this.viewId })
    }
    .width(this.winWidth > 0 ? this.winWidth : '100%')
    .height(this.winHeight > 0 ? this.winHeight : '100%')
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}
