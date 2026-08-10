import { FormExtensionAbility, formBindingData } from '@kit.FormKit';
import { fileIo } from '@kit.CoreFileKit';
import Want from '@ohos.app.ability.Want';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    let data: Record<string, Object> = {};
    try {
      // 直接读沙箱文件，避免 Preferences 缓存导致二次添加读到旧数据
      const content = fileIo.readTextSync(`${this.context.filesDir}/pending_up_card.json`);
      if (content.length > 0) {
        data = JSON.parse(content);
      }
    } catch (e) {
      console.error('EntryFormAbility', `read pending up failed: ${e}`);
    }
    return formBindingData.createFormBindingData(data);
  }
}
