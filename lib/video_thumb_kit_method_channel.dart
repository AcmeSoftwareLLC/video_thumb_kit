import 'package:flutter/foundation.dart';
import 'package:video_thumb_kit/enum.dart';
import 'package:video_thumb_kit/src/messages.g.dart' as messages;
import 'package:video_thumb_kit/video_thumb_kit_platform_interface.dart';

/// An implementation of [VideoThumbKitPlatform] that uses a Pigeon-generated
/// host API.
class MethodChannelVideoThumbKit extends VideoThumbKitPlatform {
  MethodChannelVideoThumbKit({
    @visibleForTesting messages.VideoThumbKitHostApi? hostApi,
  }) : hostApi = hostApi ?? messages.VideoThumbKitHostApi();

  /// The host API used to interact with the native platform.
  @visibleForTesting
  final messages.VideoThumbKitHostApi hostApi;

  static messages.ImageFormat _toMessageFormat(ImageFormat imageFormat) =>
      messages.ImageFormat.values[imageFormat.index];

  @override
  Future<String?> thumbnailFile(
      {required String video,
      Map<String, String>? headers,
      String? thumbnailPath,
      ImageFormat imageFormat = ImageFormat.png,
      int maxHeight = 0,
      int maxWidth = 0,
      int timeMs = 0,
      int quality = 10}) async {
    if (video.isEmpty) return null;
    final request = messages.ThumbnailRequest(
      video: video,
      headers: headers,
      path: thumbnailPath,
      imageFormat: _toMessageFormat(imageFormat),
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      timeMs: timeMs,
      quality: quality,
    );
    return await hostApi.generateThumbnailFile(request);
  }

  @override
  Future<Uint8List?> thumbnailData({
    required String video,
    Map<String, String>? headers,
    ImageFormat imageFormat = ImageFormat.png,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    assert(video.isNotEmpty);
    final request = messages.ThumbnailRequest(
      video: video,
      headers: headers,
      imageFormat: _toMessageFormat(imageFormat),
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      timeMs: timeMs,
      quality: quality,
    );
    return await hostApi.generateThumbnailData(request);
  }
}
