import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { fileIo } from '@kit.CoreFileKit';
import Want from '@ohos.app.ability.Want';
import { downloadImageBase64, fetchLatestUploads, fetchUserInfo, UploadItem, UserInfo } from '../common/biliApi';

interface UpData {
  mid: string;
  name: string;
  avatar: string;
  topPhoto: string;
  latestTitle: string;
  latestTime: string;
  latestLength: string;
}

const PENDING_FILE = 'pending_up_card.json';
const MAP_FILE = 'form_up_map.json';

export default class EntryFormAbility extends FormExtensionAbility {
  /// 串行化刷新队列：避免并发 refreshForm 读取旧值覆盖已写入的最新标题
  private refreshChain: Promise<void> = Promise.resolve();

  private filePath(name: string): string {
    return `${this.context.filesDir}/${name}`;
  }

  private readJson(name: string): Record<string, Object> {
    try {
      const content = fileIo.readTextSync(this.filePath(name));
      if (content.length > 0) {
        return JSON.parse(content) as Record<string, Object>;
      }
    } catch (e) {
      console.error('EntryFormAbility', `read ${name} failed: ${e}`);
    }
    return {};
  }

  private writeJson(name: string, data: Record<string, Object>): void {
    try {
      const file = fileIo.openSync(
        this.filePath(name),
        fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC
      );
      fileIo.writeSync(file.fd, JSON.stringify(data));
      fileIo.closeSync(file);
    } catch (e) {
      console.error('EntryFormAbility', `write ${name} failed: ${e}`);
    }
  }

  private queueRefresh(formId: string): void {
    this.refreshChain = this.refreshChain
      .then(async (): Promise<void> => {
        await this.refreshForm(formId);
      })
      .catch((): void => {
        // refreshForm 内部已 try/catch，此处仅兜底防止队列中断
      });
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    console.info('EntryFormAbility', 'onAddForm called');
    // FormExtensionAbility 无 onFormCreated 回调，卡片 ID 需从 want 的 form_identity 获取
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY];
    if (typeof formId === 'string' && formId.length > 0) {
      this.initMapEntry(formId);
    }
    return formBindingData.createFormBindingData(this.readJson(PENDING_FILE));
  }

  private initMapEntry(formId: string): void {
    const pending = this.readJson(PENDING_FILE);
    const mid = String(pending['mid'] ?? '');
    if (mid.length === 0) {
      return;
    }
    const map = this.readJson(MAP_FILE);
    const existing = map[formId] as UpData | undefined;
    if (existing && existing.mid.length > 0) {
      return;
    }
    const entry: UpData = {
      mid: mid,
      name: String(pending['name'] ?? ''),
      avatar: String(pending['avatar'] ?? ''),
      topPhoto: String(pending['topPhoto'] ?? ''),
      latestTitle: '',
      latestTime: '',
      latestLength: ''
    };
    map[formId] = entry;
    this.writeJson(MAP_FILE, map);
    console.info('EntryFormAbility', `initMapEntry formId=${formId} mid=${mid}`);
    this.queueRefresh(formId);
  }

  onUpdateForm(formId: string): void {
    console.info('EntryFormAbility', `onUpdateForm formId=${formId}`);
    this.queueRefresh(formId);
  }

  private async refreshForm(formId: string): Promise<void> {
    console.info('EntryFormAbility', `refreshForm start formId=${formId}`);
    try {
      const map = this.readJson(MAP_FILE);
      let up = map[formId] as UpData | undefined;
      if (!up || up.mid.length === 0) {
        // 兜底：map 无该 formId（onAddForm 未取到 form_identity 时），从 pending 初始化
        const pending = this.readJson(PENDING_FILE);
        const mid = String(pending['mid'] ?? '');
        if (mid.length === 0) {
          console.warn('EntryFormAbility', `refreshForm SKIP formId=${formId} no pending`);
          return;
        }
        const entry: UpData = {
          mid: mid,
          name: String(pending['name'] ?? ''),
          avatar: String(pending['avatar'] ?? ''),
          topPhoto: String(pending['topPhoto'] ?? ''),
          latestTitle: '',
          latestTime: '',
          latestLength: ''
        };
        map[formId] = entry;
        this.writeJson(MAP_FILE, map);
        up = entry;
        console.info('EntryFormAbility', `refreshForm init from pending formId=${formId}`);
      }
      const mid = Number(up.mid);
      const data: UpData = {
        mid: up.mid,
        name: up.name,
        avatar: up.avatar,
        topPhoto: up.topPhoto,
        latestTitle: up.latestTitle,
        latestTime: up.latestTime,
        latestLength: up.latestLength
      };
      let anySuccess: boolean = false;
      // 用户信息与最新投稿并行抓取（先发起请求再分别 await，一个失败不影响另一个）
      const infoPromise = fetchUserInfo(mid);
      const uploadsPromise = fetchLatestUploads(mid);
      let info: UserInfo | null = null;
      let uploads: UploadItem[] | null = null;
      try {
        info = await infoPromise;
      } catch (e) {
        console.error('EntryFormAbility', `refresh user info failed: ${e}`);
      }
      try {
        uploads = await uploadsPromise;
      } catch (e) {
        console.error('EntryFormAbility', `refresh uploads failed: ${e}`);
      }
      if (info !== null) {
        anySuccess = true;
        if (info.name.length > 0) {
          data.name = info.name;
        }
        // 头像与顶图并行下载（带进程内缓存，UP 未换头像时零网络请求）
        const facePromise = this.downloadFallback(info.face, '@240w_240h.jpg');
        const photoPromise = this.downloadFallback(info.topPhoto, '@800w_300h.jpg');
        const avatarData = await facePromise;
        const photoData = await photoPromise;
        if (avatarData.length > 0) {
          data.avatar = avatarData;
        }
        if (photoData.length > 0) {
          data.topPhoto = photoData;
        }
      }
      if (uploads !== null && uploads.length > 0) {
        anySuccess = true;
        data.latestTitle = uploads[0].title;
        data.latestLength = uploads[0].length;
        data.latestTime = formatTime(uploads[0].created);
      }
      // 本轮无任何数据：不写入、不推送，保留卡片已有内容（避免覆盖最新标题）
      if (!anySuccess) {
        console.warn('EntryFormAbility', `refresh ${formId} no data, keep old`);
        return;
      }
      map[formId] = data;
      this.writeJson(MAP_FILE, map);
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
    } catch (e) {
      console.error('EntryFormAbility', `refresh ${formId} failed: ${e}`);
    }
  }

  /// 头像/顶图 base64 缓存（key = URL+后缀），URL 不变时复用，避免每次刷新重复下载
  private imageCache: Map<string, string> = new Map();

  private async downloadFallback(url: string, suffix: string): Promise<string> {
    if (url.length === 0) {
      return '';
    }
    const key = url + suffix;
    const cached = this.imageCache.get(key);
    if (cached !== undefined) {
      return cached;
    }
    let data = await downloadImageBase64(url + suffix);
    if (data.length === 0) {
      data = await downloadImageBase64(url);
    }
    if (data.length > 0) {
      this.imageCache.set(key, data);
    }
    return data;
  }
}

function formatTime(ts: number): string {
  const d = new Date(ts * 1000);
  const pad = (n: number): string => (n < 10 ? '0' + n : '' + n);
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

