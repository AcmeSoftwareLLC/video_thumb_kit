import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'video_thumb_kit',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/com/acmesoftware/video_thumb_kit/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.acmesoftware.video_thumb_kit'),
    cppHeaderOut: 'windows/messages.g.h',
    cppSourceOut: 'windows/messages.g.cpp',
    cppOptions: CppOptions(namespace: 'video_thumb_kit'),
  ),
)
/// Wire-format image encoding for generated thumbnails.
///
/// Member order must stay `jpeg, png, webp` to match the public
/// `lib/enum.dart` `ImageFormat` and the raw `.index` values that native
/// implementations previously switched on.
enum ImageFormat { jpeg, png, webp }

class ThumbnailRequest {
  ThumbnailRequest({
    required this.video,
    this.headers,
    this.path,
    required this.imageFormat,
    required this.maxHeight,
    required this.maxWidth,
    required this.timeMs,
    required this.quality,
  });

  String video;
  Map<String, String>? headers;
  String? path;
  ImageFormat imageFormat;
  int maxHeight;
  int maxWidth;
  int timeMs;
  int quality;
}

@HostApi()
abstract class VideoThumbKitHostApi {
  @async
  String? generateThumbnailFile(ThumbnailRequest request);

  @async
  Uint8List? generateThumbnailData(ThumbnailRequest request);
}
