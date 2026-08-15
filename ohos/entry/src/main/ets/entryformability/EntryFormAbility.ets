import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { fileIo } from '@kit.CoreFileKit';
import Want from '@ohos.app.ability.Want';
import { downloadImageBase64, fetchLatestUploads, fetchUserInfo, UploadItem, UserInfo } from '../common/biliApi';

interface UpItem {
  bvid: string;
  title: string;
  created: number;
  pic: string;
  picUrl: string;
  time: string;
}

interface UpData {
  mid: string;
  name: string;
  avatar: string;
  topPhoto: string;
  avatarUrl?: string;
  topPhotoUrl?: string;
  latestTitle?: string;
  latestTime?: string;
  form: string;
  uploads: UpItem[];
}

interface UpBindingData {
  mid: string;
  name: string;
  avatar: string;
  topPhoto: string;
  latestTitle: string;
  latestTime: string;
  uploadsJson: string;
}

const PENDING_FILE = 'pending_up_card.json';
const FACE_SUFFIX = '@150w_150h_10q.webp';
const TOP_PHOTO_SUFFIX = '@400h_20q.webp';
const COVER_SUFFIX = '@160w_90h_1e_1c.webp';
const MAX_UPLOADS = 3;

export default class EntryFormAbility extends FormExtensionAbility {
  /// 串行化刷新队列：避免并发 refreshForm 读取旧值覆盖已写入的最新标题
  private refreshChain: Promise<void> = Promise.resolve();

  private filePath(name: string): string {
    return `${this.context.filesDir}/${name}`;
  }

  /// 每张卡片的持久化数据需要隔离，防止大量卡片数据下不必要的读取
  private formFileName(formId: string): string {
    return `form_${formId}.json`;
  }

  private readJson(name: string): UpData {
    try {
      const content = fileIo.readTextSync(this.filePath(name));
      if (content.length > 0) {
        return JSON.parse(content) as UpData;
      }
    } catch (e) {
      console.error('EntryFormAbility', `read ${name} failed: ${e}`);
    }
    return {
      mid: "",
      name: "",
      avatar: "",
      topPhoto: "",
      avatarUrl: "",
      topPhotoUrl: "",
      latestTitle: "",
      latestTime: "",
      form: "up_card",
      uploads: [],
    };
  }

  /// 组装下发给卡片的绑定数据：投稿列表序列化为字符串
  private bindingData(data: UpData): formBindingData.FormBindingData {
    const b: UpBindingData = {
      mid: data.mid,
      name: data.name,
      avatar: data.avatar,
      topPhoto: data.topPhoto,
      latestTitle: data.latestTitle ?? "",
      latestTime: data.latestTime ?? "",
      uploadsJson: JSON.stringify(data.uploads),
    };
    return formBindingData.createFormBindingData(b);
  }

  private writeJson(name: string, data: UpData): void {
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
    const formName = want.parameters?.[formInfo.FormParam.NAME_KEY];
    const form = typeof formName === 'string' && formName.length > 0 ? formName : 'up_card';
    if (typeof formId === 'string' && formId.length > 0) {
      this.initFormFile(formId, form);
      return this.bindingData(this.readJson(this.formFileName(formId)));
    }
    return this.bindingData(this.readJson(PENDING_FILE));
  }

  /// 为新卡片创建独立的 form_<formId>.json（从待添加数据初始化），并立即刷新一次
  private initFormFile(formId: string, form: string): void {
    const pending = this.readJson(PENDING_FILE);
    const mid = pending.mid;
    if (mid.length === 0) {
      return;
    }
    const name = this.formFileName(formId);
    const existing = this.readJson(name);
    if (existing.mid.length > 0) {
      return;
    }
    const entry: UpData = {
      mid: mid,
      name: pending.name,
      avatar: pending.avatar,
      topPhoto: pending.topPhoto,
      avatarUrl: '',
      topPhotoUrl: '',
      latestTitle: '',
      latestTime: '',
      form: form,
      uploads: [],
    };
    this.writeJson(name, entry);
    console.info('EntryFormAbility', `initFormFile formId=${formId} mid=${mid} form=${form}`);
    this.queueRefresh(formId);
  }

  onUpdateForm(formId: string): void {
    console.info('EntryFormAbility', `onUpdateForm formId=${formId}`);
    this.queueRefresh(formId);
  }

  /// 卡片内消息事件（如刷新按钮点击）触发立即刷新
  onFormEvent(formId: string, message: string): void {
    console.info('EntryFormAbility', `onFormEvent formId=${formId} message=${message}`);
    this.queueRefresh(formId);
  }

  /// 删除卡片的回调被触发时，需要移除该卡片的持久化数据
  onRemoveForm(formId: string): void {
    console.info('EntryFormAbility', `onRemoveForm formId=${formId}`);
    try {
      fileIo.unlinkSync(this.filePath(this.formFileName(formId)));
    } catch (e) {
      console.error('EntryFormAbility', `onRemoveForm unlink ${formId} failed: ${e}`);
    }
  }

  private async refreshForm(formId: string): Promise<void> {
    console.info('EntryFormAbility', `refreshForm start formId=${formId}`);
    try {
      const name = this.formFileName(formId);
      const up0 = this.readJson(name) as UpData;
      let up = up0;
      if (up.mid.length === 0) {
        // 兜底：卡片文件缺失（onAddForm 未取到 form_identity 时），从 pending 初始化
        const pending = this.readJson(PENDING_FILE);
        const mid = pending.mid;
        if (mid.length === 0) {
          console.warn('EntryFormAbility', `refreshForm SKIP formId=${formId} no pending`);
          return;
        }
        const entry: UpData = {
          mid: mid,
          name: pending.name,
          avatar: pending.avatar,
          topPhoto: pending.topPhoto,
          avatarUrl: '',
          topPhotoUrl: '',
          latestTitle: '',
          latestTime: '',
          form: 'up_card',
          uploads: [],
        };
        this.writeJson(name, entry);
        up = entry;
        console.info('EntryFormAbility', `refreshForm init from pending formId=${formId}`);
      }
      const mid = Number(up.mid);
      const data: UpData = {
        mid: up.mid,
        name: up.name,
        avatar: up.avatar,
        topPhoto: up.topPhoto,
        avatarUrl: up.avatarUrl,
        topPhotoUrl: up.topPhotoUrl,
        latestTitle: up.latestTitle,
        latestTime: up.latestTime,
        form: up.form ?? 'up_card',
        uploads: up.uploads ?? [],
      };
      let anySuccess: boolean = false;
      // 用户信息与最新投稿并行抓取（先发起请求再分别 await，一个失败不影响另一个）
      const infoPromise = fetchUserInfo(mid);
      const uploadsPromise = fetchLatestUploads(mid, MAX_UPLOADS);
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
        // 头像/顶图 URL（含后缀）持久化在卡片 json 中：URL 与上次一致（UP 未换图）则复用已存 base64，
        // 变化时才重新下载，无需进程内缓存，跨进程/重启同样生效
        const faceUrl = info.face.length > 0 ? info.face + FACE_SUFFIX : '';
        const photoUrl = info.topPhoto.length > 0 ? info.topPhoto + TOP_PHOTO_SUFFIX : '';
        if (faceUrl.length > 0 && faceUrl !== up.avatarUrl) {
          const avatarData = await downloadImageBase64(faceUrl);
          if (avatarData.length > 0) {
            data.avatar = avatarData;
            data.avatarUrl = faceUrl;
          } else {
            // 下载失败：保留旧图与旧 URL，下次刷新再试
            data.avatarUrl = up.avatarUrl;
          }
        } else {
          data.avatarUrl = up.avatarUrl;
        }
        if (photoUrl.length > 0 && photoUrl !== up.topPhotoUrl) {
          const photoData = await downloadImageBase64(photoUrl);
          if (photoData.length > 0) {
            data.topPhoto = photoData;
            data.topPhotoUrl = photoUrl;
          } else {
            data.topPhotoUrl = up.topPhotoUrl;
          }
        } else {
          data.topPhotoUrl = up.topPhotoUrl;
        }
      }
      if (uploads !== null && uploads.length > 0) {
        anySuccess = true;
        data.latestTitle = uploads[0].title;
        data.latestTime = formatTime(uploads[0].created);
        // 投稿列表：2*4 卡片下载封面（URL 一致则复用已存 base64），其余卡片只保留标题
        const needCovers = up.form === 'up_card_24';
        const oldList = up.uploads ?? [];
        const items: UpItem[] = [];
        const count = Math.min(uploads.length, MAX_UPLOADS);
        for (let i = 0; i < count; i++) {
          const raw = uploads[i].pic;
          const url = needCovers && raw.length > 0 ? raw.replace('http://', 'https://') + COVER_SUFFIX : '';
          const old = i < oldList.length ? oldList[i] : undefined;
          let pic = '';
          if (url.length > 0 && old !== undefined && old.picUrl === url && old.pic.length > 0) {
            pic = old.pic;
          } else if (url.length > 0) {
            const coverData = await downloadImageBase64(url);
            if (coverData.length > 0) {
              pic = coverData;
            }
          }
          // 封面下载失败时 picUrl 置空，下次刷新会重新拉取
          items.push({
            bvid: uploads[i].bvid,
            title: uploads[i].title,
            created: uploads[i].created,
            pic: pic,
            picUrl: pic.length > 0 ? url : '',
            //这里使用带年份的时间
            time: formatFullTime(uploads[i].created),
          });
        }
        data.uploads = items;
      }
      // 本轮无任何数据：不写入、不推送，保留卡片已有内容（避免覆盖最新标题）
      if (!anySuccess) {
        console.warn('EntryFormAbility', `refresh ${formId} no data, keep old`);
        return;
      }
      this.writeJson(name, data);
      await formProvider.updateForm(formId, this.bindingData(data));
    } catch (e) {
      console.error('EntryFormAbility', `refresh ${formId} failed: ${e}`);
    }
  }

}

function formatTime(ts: number): string {
  const d = new Date(ts * 1000);
  const pad = (n: number): string => (n < 10 ? '0' + n : '' + n);
  return `${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

function formatFullTime(ts: number): string {
  const d = new Date(ts * 1000);
  const pad = (n: number): string => (n < 10 ? '0' + n : '' + n);
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

