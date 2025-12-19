import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import type { Permissions } from '@ohos.abilityAccessCtrl';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import wantAgent from '@ohos.wantAgent';
import type common from '@ohos.app.ability.common';
import hilog from '@ohos.hilog';

interface SimpleWant {
  bundleName: string;
  abilityName: string;
}

interface SimpleWantAgentInfo {
  wants: Array<SimpleWant>;
  operationType: wantAgent.OperationType;
  requestCode: number;
  flags: Array<number>;
}

/**
 * 控制后台长时任务（音频播放）开启/关闭，仅 Harmony 使用
 */
export default class BackgroundPlugin
  implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  private bgReady: boolean = false;
  private bgEnabled: boolean = false;

  getUniqueClassName(): string {
    return 'BackgroundPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(
      binding.getBinaryMessenger(),
      'com.piliplus/background',
    );
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(_: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    /* no-op */
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    if (!this.context) {
      result.error('NO_CONTEXT', 'UIAbilityContext is null', null);
      return;
    }

    if (call.method === 'enableBackground') {
      const enable: boolean = call.argument('enable') ?? false;
      if (enable) {
        await this.ensureBackgroundRunning();
      } else {
        await this.stopBackgroundRunning();
      }
      result.success(true);
    } else {
      result.notImplemented();
    }
  }

  private async ensureBackgroundRunning(): Promise<void> {
    if (this.bgEnabled) return;
    if (!this.bgReady) {
      const permissions: Array<Permissions> = ['ohos.permission.KEEP_BACKGROUND_RUNNING'];
      try {
        const data = await abilityAccessCtrl.createAtManager()
          .requestPermissionsFromUser(this.context!, permissions);
        const grantResults = data.authResults ?? [];
        const granted = grantResults.every((res: number) => res === 0);
        if (!granted) {
          hilog.warn(0x0001, 'BackgroundPlugin', 'KEEP_BACKGROUND_RUNNING not granted by user');
          return;
        }
        this.bgReady = true;
      } catch (err) {
        hilog.error(0x0001, 'BackgroundPlugin', `Request perm failed: ${JSON.stringify(err)}`);
        return;
      }
    }
    await this.startBgTask();
    this.bgEnabled = true;
  }

  private async stopBackgroundRunning(): Promise<void> {
    if (!this.bgEnabled) return;
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context!);
      this.bgEnabled = false;
    } catch (err) {
      hilog.error(0x0001, 'BackgroundPlugin', `stopBackgroundRunning error: ${JSON.stringify(err)}`);
    }
  }

  private async startBgTask() {
    const agent = await this.buildWantAgent();
    await backgroundTaskManager.startBackgroundRunning(
      this.context!,
      backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,
      agent,
    );
  }

  private async buildWantAgent() {
    const wants: Array<SimpleWant> = [
      {
        bundleName: this.context?.abilityInfo?.bundleName ?? 'com.example.piliplus',
        abilityName: 'EntryAbility',
      },
    ];
    const flags: Array<number> = [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG];
    const info: SimpleWantAgentInfo = {
      wants: wants,
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      flags: flags,
    };
    return await wantAgent.getWantAgent(info);
  }
}

