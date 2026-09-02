import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_thumb_kit/enum.dart';
import 'package:video_thumb_kit/src/messages.g.dart' as messages;
import 'package:video_thumb_kit/video_thumb_kit_method_channel.dart';

class _FakeHostApi extends messages.VideoThumbKitHostApi {
  messages.ThumbnailRequest? lastRequest;
  String? fileResult = '/tmp/thumb.png';
  Uint8List? dataResult = Uint8List.fromList(<int>[1, 2, 3]);

  @override
  Future<String?> generateThumbnailFile(
    messages.ThumbnailRequest request,
  ) async {
    lastRequest = request;
    return fileResult;
  }

  @override
  Future<Uint8List?> generateThumbnailData(
    messages.ThumbnailRequest request,
  ) async {
    lastRequest = request;
    return dataResult;
  }
}

void main() {
  late _FakeHostApi hostApi;
  late MethodChannelVideoThumbKit plugin;

  setUp(() {
    hostApi = _FakeHostApi();
    plugin = MethodChannelVideoThumbKit(hostApi: hostApi);
  });

  group('MethodChannelVideoThumbKit.thumbnailFile', () {
    test('returns null and skips the host API for empty video path', () async {
      final result = await plugin.thumbnailFile(video: '');
      expect(result, isNull);
      expect(hostApi.lastRequest, isNull);
    });

    test('sends correct request', () async {
      final headers = <String, String>{'Authorization': 'Bearer token'};
      final result = await plugin.thumbnailFile(
        video: '/video.mp4',
        headers: headers,
        thumbnailPath: '/tmp/out.png',
        imageFormat: ImageFormat.webp,
        maxHeight: 200,
        maxWidth: 300,
        timeMs: 1500,
        quality: 90,
      );

      expect(result, '/tmp/thumb.png');
      final request = hostApi.lastRequest;
      expect(request, isNotNull);
      expect(request!.video, '/video.mp4');
      expect(request.headers, headers);
      expect(request.path, '/tmp/out.png');
      expect(request.imageFormat, messages.ImageFormat.webp);
      expect(request.maxHeight, 200);
      expect(request.maxWidth, 300);
      expect(request.timeMs, 1500);
      expect(request.quality, 90);
    });
  });

  group('MethodChannelVideoThumbKit.thumbnailData', () {
    test('asserts when video path is empty', () {
      expect(() => plugin.thumbnailData(video: ''), throwsAssertionError);
    });

    test('sends correct request and returns bytes', () async {
      final headers = <String, String>{'X-Header': 'value'};
      final result = await plugin.thumbnailData(
        video: '/video.mov',
        headers: headers,
        imageFormat: ImageFormat.jpeg,
        maxHeight: 100,
        maxWidth: 120,
        timeMs: 250,
        quality: 70,
      );

      expect(result, Uint8List.fromList(<int>[1, 2, 3]));
      final request = hostApi.lastRequest;
      expect(request, isNotNull);
      expect(request!.video, '/video.mov');
      expect(request.headers, headers);
      expect(request.path, isNull);
      expect(request.imageFormat, messages.ImageFormat.jpeg);
      expect(request.maxHeight, 100);
      expect(request.maxWidth, 120);
      expect(request.timeMs, 250);
      expect(request.quality, 70);
    });
  });
}
