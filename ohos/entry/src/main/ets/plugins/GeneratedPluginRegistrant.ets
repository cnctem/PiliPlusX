import { FlutterEngine } from '@ohos/flutter_ohos';

import AppLinksOhosPlugin from 'app_links_ohos';
import AutoOrientationPlugin from 'auto_orientation';
import BatteryPlusPlugin from 'battery_plus_ohos';
import ConnectivityPlusOhosPlugin from 'connectivity_plus_ohos';
import DeviceInfoPlusPlugin from 'device_info_plus_ohos';
import InAppWebViewFlutterPlugin from 'flutter_inappwebview_ohos';
import ImagePickerPulgin from 'image_picker_ohos';
import MediaKitLibsOhosPlugin from 'media_kit_libs_ohos';
import MediaKitVideoPlugin from 'media_kit_video';
import PackageInfoPlusPlugin from 'package_info_plus_ohos';
import PathProviderPlugin from 'path_provider_ohos';
import SaverGalleryPlugin from 'saver_gallery';
import SharePlusPlugin from 'share_plus';
import UrlLauncherPlugin from 'url_launcher_ohos';
import VideoPlayerPlugin from 'video_player_ohos';
import WakelockPlugin from 'wakelock_plus_ohos';

export class GeneratedPluginRegistrant {
  static registerWith(flutterEngine: FlutterEngine) {
    const plugins = flutterEngine.getPlugins();
    plugins?.add(new AppLinksOhosPlugin());
    plugins?.add(new AutoOrientationPlugin());
    plugins?.add(new BatteryPlusPlugin());
    plugins?.add(new ConnectivityPlusOhosPlugin());
    plugins?.add(new DeviceInfoPlusPlugin());
    plugins?.add(new InAppWebViewFlutterPlugin());
    plugins?.add(new ImagePickerPulgin());
    plugins?.add(new MediaKitLibsOhosPlugin());
    plugins?.add(new MediaKitVideoPlugin());
    plugins?.add(new PackageInfoPlusPlugin());
    plugins?.add(new PathProviderPlugin());
    plugins?.add(new SaverGalleryPlugin());
    plugins?.add(new SharePlusPlugin());
    plugins?.add(new UrlLauncherPlugin());
    plugins?.add(new VideoPlayerPlugin());
    plugins?.add(new WakelockPlugin());
  }
}
