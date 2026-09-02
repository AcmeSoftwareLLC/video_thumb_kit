#include "include/video_thumb_kit/video_thumb_kit_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "video_thumb_kit_plugin.h"

void VideoThumbKitPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  video_thumb_kit::VideoThumbKitPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
