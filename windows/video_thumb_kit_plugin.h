#ifndef FLUTTER_PLUGIN_VIDEO_THUMB_KIT_PLUGIN_H_
#define FLUTTER_PLUGIN_VIDEO_THUMB_KIT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace video_thumb_kit {

class VideoThumbKitPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  VideoThumbKitPlugin();
  ~VideoThumbKitPlugin() override;

  VideoThumbKitPlugin(const VideoThumbKitPlugin&) = delete;
  VideoThumbKitPlugin& operator=(const VideoThumbKitPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace video_thumb_kit

#endif  // FLUTTER_PLUGIN_VIDEO_THUMB_KIT_PLUGIN_H_
