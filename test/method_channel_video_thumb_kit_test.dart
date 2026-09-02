import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_thumb_kit/enum.dart';
import 'package:video_thumb_kit/video_thumb_kit_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('video_thumb_kit');
  late MethodChannelVideoThumbKit plugin;

  MethodCall? lastMethodCall;

  setUp(() {
    plugin = MethodChannelVideoThumbKit();
    lastMethodCall = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      lastMethodCall = methodCall;
      if (methodCall.method == 'file') {
        return '/tmp/thumb.png';
      }
      return Uint8List.fromList(<int>[1, 2, 3]);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('MethodChannelVideoThumbKit.thumbnailFile', () {
    test('returns null and skips channel for empty video path', () async {
      final result = await plugin.thumbnailFile(video: '');
      expect(result, isNull);
      expect(lastMethodCall, isNull);
    });

    test('sends correct method and arguments', () async {
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
      expect(lastMethodCall, isNotNull);
      expect(lastMethodCall!.method, 'file');
      expect(lastMethodCall!.arguments, <String, dynamic>{
        'video': '/video.mp4',
        'headers': headers,
        'path': '/tmp/out.png',
        'format': ImageFormat.webp.index,
        'maxh': 200,
        'maxw': 300,
        'timeMs': 1500,
        'quality': 90,
      });
    });
  });

  group('MethodChannelVideoThumbKit.thumbnailData', () {
    test('asserts when video path is empty', () {
      expect(() => plugin.thumbnailData(video: ''), throwsAssertionError);
    });

    test('sends correct method and arguments and returns bytes', () async {
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
      expect(lastMethodCall, isNotNull);
      expect(lastMethodCall!.method, 'data');
      expect(lastMethodCall!.arguments, <String, dynamic>{
        'video': '/video.mov',
        'headers': headers,
        'format': ImageFormat.jpeg.index,
        'maxh': 100,
        'maxw': 120,
        'timeMs': 250,
        'quality': 70,
      });
    });
  });
}
