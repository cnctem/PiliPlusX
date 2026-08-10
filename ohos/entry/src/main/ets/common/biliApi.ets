import { http } from "@kit.NetworkKit";
import { cryptoFramework } from "@kit.CryptoArchitectureKit";
import { util } from "@kit.ArkTS";

const UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36";
const MIXIN_KEY_ENC_TAB: number[] = [
  46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35, 27, 43, 5, 49,
  33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13, 37, 48, 7, 16, 24, 55, 40, 61,
  26, 17, 0, 1, 60, 51, 30, 4, 22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11, 36,
  20, 34, 44, 52
];

let cachedMixinKey: string = "";

export interface UploadItem {
  title: string;
  length: string;
  created: number;
}

export interface UserInfo {
  name: string;
  face: string;
  topPhoto: string;
}

interface WbiImg {
  img_url?: string;
  sub_url?: string;
}

interface NavRespData {
  wbi_img?: WbiImg;
}

interface NavResp {
  code: number;
  data: NavRespData;
}

interface VideoList {
  vlist?: BiliVideo[];
}

interface SpaceRespData {
  name?: string;
  face?: string;
  top_photo?: string;
  list?: VideoList;
}

interface SpaceResp {
  code: number;
  data: SpaceRespData;
}

interface BiliVideo {
  title: string;
  length: string;
  created: number;
}

interface QueryParams {
  mid: string;
  pn?: string;
  ps?: string;
  order?: string;
  tid?: string;
  platform?: string;
  web_type?: string;
}

interface ApiResp {
  code: number;
  message: string;
}

function getMixinKey(orig: string): string {
  let res = "";
  for (let i = 0; i < 32; i++) {
    res += orig[MIXIN_KEY_ENC_TAB[i]];
  }
  return res;
}

async function md5Hex(input: string): Promise<string> {
  const md = cryptoFramework.createMd("MD5");
  const encoder = new util.TextEncoder();
  await md.update({ data: encoder.encodeInto(input) });
  const out = await md.digest();
  let hex = "";
  out.data.forEach((b: number): void => {
    hex += b.toString(16).padStart(2, "0");
  });
  return hex;
}

async function fetchMixinKey(): Promise<string> {
  if (cachedMixinKey.length > 0) {
    return cachedMixinKey;
  }
  const req = http.createHttp();
  try {
    const resp = await req.request("https://api.bilibili.com/x/web-interface/nav", {
      method: http.RequestMethod.GET,
      header: { "User-Agent": UA },
      connectTimeout: 10000,
      readTimeout: 10000
    });
    const body = JSON.parse(resp.result as string) as NavResp;
    const img = body.data?.wbi_img?.img_url ?? "";
    const sub = body.data?.wbi_img?.sub_url ?? "";
    if (img.length === 0 || sub.length === 0) {
      throw new Error("empty wbi keys");
    }
    const keyOf = (u: string): string => {
      const part = u.split("/").pop() ?? "";
      return part.split(".")[0];
    };
    cachedMixinKey = getMixinKey(keyOf(img) + keyOf(sub));
    return cachedMixinKey;
  } finally {
    req.destroy();
  }
}

function appendParam(pairs: string[], key: string, value: string | undefined): void {
  if (value !== undefined && value.length > 0) {
    pairs.push(key + "=" + encodeURIComponent(value.replace(/[!'()*]/g, "")));
  }
}

async function wbiGet(path: string, params: QueryParams, mid: number): Promise<string> {
  let attempt = 0;
  while (attempt < 2) {
    attempt++;
    console.info('biliApi', `wbiGet path=${path} attempt=${attempt}`);
    const mixinKey = await fetchMixinKey();
    const pairs: string[] = [];
    appendParam(pairs, "mid", params.mid);
    appendParam(pairs, "pn", params.pn);
    appendParam(pairs, "ps", params.ps);
    appendParam(pairs, "order", params.order);
    appendParam(pairs, "tid", params.tid);
    appendParam(pairs, "platform", params.platform);
    appendParam(pairs, "web_type", params.web_type);
    appendParam(pairs, "wts", String(Math.floor(Date.now() / 1000)));
    pairs.sort();
    const query = pairs.join("&");
    const wRid = await md5Hex(query + mixinKey);
    const req = http.createHttp();
    try {
      const resp = await req.request(`https://api.bilibili.com${path}?${query}&w_rid=${wRid}`, {
        method: http.RequestMethod.GET,
        header: {
          "User-Agent": UA,
          "Referer": `https://space.bilibili.com/${mid}`
        },
        connectTimeout: 10000,
        readTimeout: 15000
      });
      const text = resp.result as string;
      const body = JSON.parse(text) as ApiResp;
      // 签名/风控被拒：清空缓存的 mixin key，重新抓 nav 后重试一次
      if (attempt === 1 && (body.code === -352 || body.code === -403 || body.code === -412)) {
        cachedMixinKey = "";
        continue;
      }
      return text;
    } finally {
      req.destroy();
    }
  }
  throw new Error(`bili request failed: ${path}`);
}

export async function fetchUserInfo(mid: number): Promise<UserInfo> {
  const text = await wbiGet("/x/space/wbi/acc/info", { mid: String(mid) }, mid);
  const body = JSON.parse(text) as SpaceResp;
  if (body.code !== 0) {
    throw new Error(`acc/info code ${body.code}`);
  }
  const d = body.data;
  return {
    name: d.name ?? "",
    face: d.face ?? "",
    topPhoto: d.top_photo ?? ""
  };
}

export async function fetchLatestUploads(mid: number): Promise<UploadItem[]> {
  const text = await wbiGet("/x/space/wbi/arc/search", {
    mid: String(mid),
    pn: "1",
    ps: "1",
    order: "pubdate",
    tid: "0",
    platform: "web",
    web_type: "interface"
  }, mid);
  const body = JSON.parse(text) as SpaceResp;
  if (body.code !== 0) {
    throw new Error(`arc/search code ${body.code}`);
  }
  const vlist = body.data?.list?.vlist ?? [];
  return vlist.slice(0, 1).map((v: BiliVideo): UploadItem => ({
    title: v.title,
    length: v.length,
    created: v.created
  }));
}

export async function downloadImageBase64(url: string): Promise<string> {
  if (url.length === 0) {
    return "";
  }
  let httpRequest: http.HttpRequest | null = null;
  try {
    httpRequest = http.createHttp();
    const resp = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.ARRAY_BUFFER,
      connectTimeout: 15000,
      readTimeout: 15000
    });
    if (resp.responseCode !== 200) {
      return "";
    }
    const result = resp.result;
    let bytes: ArrayBuffer;
    if (result instanceof ArrayBuffer) {
      bytes = result;
    } else if (result instanceof Uint8Array) {
      bytes = result.buffer as ArrayBuffer;
    } else {
      return "";
    }
    if (bytes.byteLength === 0) {
      return "";
    }
    const mime = url.toLowerCase().includes(".webp") ? "image/webp" : "image/jpeg";
    const base64 = new util.Base64Helper().encodeToStringSync(new Uint8Array(bytes));
    return `data:${mime};base64,${base64}`;
  } catch (e) {
    return "";
  } finally {
    httpRequest?.destroy();
  }
}
