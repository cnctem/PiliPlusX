import { FormExtensionAbility, formBindingData } from '@kit.FormKit';
import { preferences } from '@kit.ArkData';
import Want from '@ohos.app.ability.Want';

const PREFS_NAME = 'pili_form';
const KEY_PENDING_UP = 'pending_up_card';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    let data: Record<string, Object> = {};
    try {
      const store = preferences.getPreferencesSync(this.context, { name: PREFS_NAME });
      const pending = store.getSync(KEY_PENDING_UP, '');
      if (typeof pending === 'string' && pending.length > 0) {
        data = JSON.parse(pending);
      }
    } catch (e) {
      console.error('EntryFormAbility', `onAddForm load pending up failed: ${e}`);
    }
    return formBindingData.createFormBindingData(data);
  }
}
