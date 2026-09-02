#ifndef FLUTTER_PLUGIN_VIDEO_THUMB_KIT_PLUGIN_H_
#define FLUTTER_PLUGIN_VIDEO_THUMB_KIT_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace video_thumb_kit {

class VideoThumbKitPlugin : public flutter::Plugin, public VideoThumbKitHostApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  VideoThumbKitPlugin();
  ~VideoThumbKitPlugin() override;

  VideoThumbKitPlugin(const VideoThumbKitPlugin&) = delete;
  VideoThumbKitPlugin& operator=(const VideoThumbKitPlugin&) = delete;

  // VideoThumbKitHostApi
  void GenerateThumbnailFile(
      const ThumbnailRequest& request,
      std::function<void(ErrorOr<std::optional<std::string>> reply)> result) override;
  void GenerateThumbnailData(
      const ThumbnailRequest& request,
      std::function<void(ErrorOr<std::optional<std::vector<uint8_t>>> reply)> result) override;
};

}  // namespace video_thumb_kit

#endif  // FLUTTER_PLUGIN_VIDEO_THUMB_KIT_PLUGIN_H_
