import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_thumb_kit/enum.dart';
import 'package:video_thumb_kit/video_thumb_kit_method_channel.dart';

abstract class VideoThumbKitPlatform extends PlatformInterface {
  /// Constructs a VideoThumbKitPlatform.
  VideoThumbKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoThumbKitPlatform _instance = MethodChannelVideoThumbKit();

  /// The default instance of [VideoThumbKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoThumbKit].
  static VideoThumbKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoThumbKitPlatform] when
  /// they register themselves.
  static set instance(VideoThumbKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> thumbnailFile({
    required String video,
    Map<String, String>? headers,
    String? thumbnailPath,
    ImageFormat imageFormat = ImageFormat.png,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    throw UnimplementedError('thumbnailFile() has not been implemented.');
  }

  Future<Uint8List?> thumbnailData({
    required String video,
    Map<String, String>? headers,
    ImageFormat imageFormat = ImageFormat.png,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    throw UnimplementedError('thumbnailData() has not been implemented.');
  }

  Future<Uint8List?> thumbnailDataWeb({
    required Uint8List videoBytes,
    num quality = 100,
  }) async {
    throw UnimplementedError('thumbnailDataWeb() has not been implemented.');
  }
}
