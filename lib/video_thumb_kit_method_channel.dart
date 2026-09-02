import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_thumb_kit/enum.dart';
import 'package:video_thumb_kit/video_thumb_kit_platform_interface.dart';

/// An implementation of [VideoThumbKitPlatform] that uses method channels.
class MethodChannelVideoThumbKit
    extends VideoThumbKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_thumb_kit');

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
    final reqMap = <String, dynamic>{
      'video': video,
      'headers': headers,
      'path': thumbnailPath,
      'format': imageFormat.index,
      'maxh': maxHeight,
      'maxw': maxWidth,
      'timeMs': timeMs,
      'quality': quality
    };
    return await methodChannel.invokeMethod('file', reqMap);
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
    final reqMap = <String, dynamic>{
      'video': video,
      'headers': headers,
      'format': imageFormat.index,
      'maxh': maxHeight,
      'maxw': maxWidth,
      'timeMs': timeMs,
      'quality': quality,
    };
    return await methodChannel.invokeMethod('data', reqMap);
  }
}
