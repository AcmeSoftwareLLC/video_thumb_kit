<div align="center">

# 🎬 Video Thumb Kit

**Fast, cross-platform video thumbnail generation for Flutter.**

Turn a video file, URL, or raw byte array into a crisp thumbnail — as a file or in memory — with a few lines of Dart.

[![pub package](https://img.shields.io/pub/v/video_thumb_kit.svg)](https://pub.dev/packages/video_thumb_kit)
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/AcmeSoftwareLLC/video_thumb_kit?tab=BSD-3-Clause-1-ov-file)
[![Example](https://img.shields.io/badge/Example-Ex-success)](https://pub.dev/packages/video_thumb_kit/example)

</div>

---

## 📚 Table of contents

- [✨ Features](#-features)
- [📱 Platform support](#-platform-support)
- [📦 Installation](#-installation)
- [🚀 Quick start](#-quick-start)
- [🧰 API reference](#-api-reference)
- [🪟 Windows notes](#-windows-notes)
- [💡 Example use cases](#-example-use-cases)
- [🤝 Contributing](#-contributing)
- [⭐ Support this project](#-support-this-project)

---

## ✨ Features

- 🖼️ Generate thumbnails from video **files** or raw **byte arrays**
- 🎨 Multiple image formats — `PNG`, `JPG`, and `WebP`
- 📐 Fully customizable **size**, **quality**, and **timestamp**
- ⚡ Native platform implementations for optimal performance
- 💾 Get a thumbnail back as a **file path** or an in-memory `Uint8List`

## 📱 Platform support

| Platform | `thumbnailFile` | `thumbnailData` | `thumbnailDataWeb` |
| :--- | :---: | :---: | :---: |
| 🤖 Android | ✅ | ✅ | ⛔️ |
| 🍎 iOS | ✅ | ✅ | ⛔️ |
| 🖥️ macOS | ✅ | ✅ | ⛔️ |
| 🪟 Windows | ✅ | ✅ | ⛔️ |
| 🌐 Web | ⛔️ | ⛔️ | ✅ |

## 📦 Installation

Add `video_thumb_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  video_thumb_kit: ^0.0.1
```

Then fetch it:

```sh
flutter pub get
```

## 🚀 Quick start

### 1️⃣ Generate a thumbnail file

```dart
import 'package:video_thumb_kit/video_thumb_kit.dart';

Future<void> main() async {
  final videoPath = 'path/to/video.mp4';
  final thumbnailPath = 'path/to/thumbnail.png';

  final result = await VideoThumbKit.thumbnailFile(
    video: videoPath,
    thumbnailPath: thumbnailPath,
    imageFormat: ImageFormat.png,
    maxHeight: 100,
    maxWidth: 100,
    timeMs: 1000,
    quality: 10,
  );

  if (result != null) {
    print('✅ Thumbnail generated: $result');
  } else {
    print('❌ Failed to generate thumbnail');
  }
}
```

### 2️⃣ Generate thumbnail bytes from a video byte array (Web only)

```dart
import 'package:video_thumb_kit/video_thumb_kit.dart';

Future<void> main() async {
  final videoBytes = Uint8List.fromList([/* video byte array */]);

  final result = await VideoThumbKit.thumbnailDataWeb(
    videoBytes: videoBytes,
    quality: 100,
  );

  if (result != null) {
    print('✅ Thumbnail generated: ${result.lengthInBytes} bytes');
  } else {
    print('❌ Failed to generate thumbnail');
  }
}
```

## 🧰 API reference

### `VideoThumbKit.thumbnailFile(...)`

Generates a thumbnail from a video file and saves it to disk. Returns the path to the generated file, or `null` on failure.

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `video` | `String` | *required* | Path to the source video file |
| `headers` | `Map<String, String>?` | `null` | Optional headers sent with the request |
| `thumbnailPath` | `String?` | `null` | Where to save the thumbnail (auto-generated if omitted) |
| `imageFormat` | `ImageFormat` | `ImageFormat.png` | Output image format |
| `maxHeight` | `int` | `0` (unbounded) | Maximum thumbnail height |
| `maxWidth` | `int` | `0` (unbounded) | Maximum thumbnail width |
| `timeMs` | `int` | `0` | Timestamp in the video to capture, in milliseconds |
| `quality` | `int` | `10` | Output image quality |

### `VideoThumbKit.thumbnailData(...)`

Same as above, but returns the thumbnail as a `Uint8List` instead of writing to disk. Accepts the same parameters (minus `thumbnailPath`).

### `VideoThumbKit.thumbnailDataWeb(...)`

Generates a thumbnail from a raw video byte array — **Web only**. Returns a `Uint8List`, or `null` on failure.

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `videoBytes` | `Uint8List` | *required* | The source video as a byte array |
| `quality` | `num` | `100` | Output image quality |

## 🪟 Windows notes

- Uses a native `MethodChannel` implementation — the same API contract as Android/iOS/macOS
- Thumbnail extraction uses **Media Foundation**; image encoding uses **WIC**
- `ImageFormat.webp` currently falls back to PNG for compatibility
- If `thumbnailPath` is omitted, output is written to the OS temp directory

## 💡 Example use cases

- 🎞️ Thumbnails for video playback screens
- 🖼️ Building a video gallery grid
- 📤 Sharing video previews on social media

> See the full [example app](https://github.com/AcmeSoftwareLLC/video_thumb_kit) for a complete, runnable demo.

## 🤝 Contributing

Contributions are welcome! Fork the repository, make your changes, and submit a pull request. 🙌

## ⭐ Support this project

If `video_thumb_kit` helped you ship faster, consider starring the repo — it genuinely helps! Found a bug? [Open an issue](https://github.com/AcmeSoftwareLLC/video_thumb_kit/issues) and we'll take a look.
