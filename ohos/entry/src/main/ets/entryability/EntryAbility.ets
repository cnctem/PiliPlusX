import { common } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { fileIo, fileUri, picker } from "@kit.CoreFileKit";
import AbilityConstant from "@ohos.app.ability.AbilityConstant";
import type Want from "@ohos.app.ability.Want";
import window from "@ohos.window";
import { FlutterAbility, FlutterEngine } from "@ohos/flutter_ohos";
import { GeneratedPluginRegistrant } from "../plugins/GeneratedPluginRegistrant";
import HarmonyChannel from "../plugins/HarmonyChannel";

export default class EntryAbility extends FlutterAbility {
  harmonyChannel: HarmonyChannel = new HarmonyChannel();
  wasFloatingWindow: boolean = false;

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    flutterEngine.getPlugins()?.add(this.harmonyChannel);
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    super.onCreate(want, launchParam);
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    super.onWindowStageCreate(windowStage);
    let w = windowStage.getMainWindowSync();
    w.on("windowStatusChange", (type) => {
      if (type == window.WindowStatusType.FLOATING && !this.wasFloatingWindow) {
        this.harmonyChannel.onFloatingWindowChange(true);
        this.wasFloatingWindow = true;
      } else if (this.wasFloatingWindow && type != window.WindowStatusType.FLOATING) {
        this.harmonyChannel.onFloatingWindowChange(false);
        this.wasFloatingWindow = false;
      }
    });
    await setTimeout(() => {
      let context = getContext() as common.UIAbilityContext;
      const documentViewPicker = new picker.DocumentViewPicker(context);
      const documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
      documentViewPicker
        .save(documentSaveOptions)
        .catch((err: BusinessError) => {
          console.error('测试：' +
            `Invoke documentViewPicker.save failed, code is ${err.code}, message is ${err.message}`,
          );
        });
      console.log('测试：' + '创建下载文件夹成功')
    }, 100)
  }
}
