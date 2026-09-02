import AVFoundation
import Flutter
import UIKit

public class VideoThumbKitPlugin: NSObject, FlutterPlugin, VideoThumbKitHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = VideoThumbKitPlugin()
    VideoThumbKitHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  func generateThumbnailFile(request: ThumbnailRequest) async throws -> String? {
    try await Self.performInBackground {
      try Self.buildThumbnailFile(request: request)
    }
  }

  func generateThumbnailData(request: ThumbnailRequest) async throws -> FlutterStandardTypedData? {
    let data = try await Self.performInBackground {
      try Self.buildThumbnailData(request: request)
    }
    guard let data else { return nil }
    return FlutterStandardTypedData(bytes: data)
  }

  private static func performInBackground<T>(_ work: @escaping () throws -> T) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          continuation.resume(returning: try work())
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  private static func resolveVideoURL(_ video: String) throws -> URL {
    if video.hasPrefix("file://") {
      return URL(fileURLWithPath: String(video.dropFirst(7)))
    }
    if video.hasPrefix("/") {
      return URL(fileURLWithPath: video)
    }
    guard let url = URL(string: video) else {
      throw PigeonError(code: "invalid_url", message: "Invalid video URL", details: nil)
    }
    return url
  }

  private static func buildThumbnailData(request: ThumbnailRequest) throws -> Data? {
    let url = try resolveVideoURL(request.video)
    return generateThumbnail(
      url: url,
      headers: request.headers,
      format: request.imageFormat,
      maxHeight: Int(request.maxHeight),
      maxWidth: Int(request.maxWidth),
      timeMs: Int(request.timeMs),
      quality: Int(request.quality))
  }

  private static func buildThumbnailFile(request: ThumbnailRequest) throws -> String? {
    guard let data = try buildThumbnailData(request: request) else {
      throw PigeonError(code: "IO Error", message: "Failed to write data to file", details: nil)
    }

    let videoURL = try resolveVideoURL(request.video)
    let ext = fileExtension(for: request.imageFormat)
    var thumbnailURL = videoURL.deletingPathExtension().appendingPathExtension(ext)

    if let path = request.path, !path.isEmpty {
      let lastPart = thumbnailURL.lastPathComponent
      thumbnailURL = URL(fileURLWithPath: path)
      if thumbnailURL.pathExtension != ext {
        thumbnailURL = thumbnailURL.appendingPathComponent(lastPart)
      }
    }

    do {
      try data.write(to: thumbnailURL, options: .atomic)
    } catch {
      throw PigeonError(code: "IO Error", message: "Failed to write data to file", details: nil)
    }

    var fullpath = thumbnailURL.absoluteString
    if fullpath.hasPrefix("file://") {
      fullpath = String(fullpath.dropFirst(7))
    }
    return fullpath
  }

  private static func fileExtension(for format: ImageFormat) -> String {
    switch format {
    case .jpeg: return "jpg"
    case .png: return "png"
    case .webp: return "webp"
    }
  }

  private static func generateThumbnail(
    url: URL,
    headers: [String: String]?,
    format: ImageFormat,
    maxHeight: Int,
    maxWidth: Int,
    timeMs: Int,
    quality: Int
  ) -> Data? {
    var options: [String: Any] = [:]
    if let headers {
      options["AVURLAssetHTTPHeaderFieldsKey"] = headers
    }

    let asset = AVURLAsset(url: url, options: options.isEmpty ? nil : options)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    imageGenerator.maximumSize = CGSize(width: maxWidth, height: maxHeight)
    imageGenerator.requestedTimeToleranceBefore = .zero
    imageGenerator.requestedTimeToleranceAfter = CMTime(value: 100, timescale: 1000)

    let targetTime = CMTime(value: Int64(timeMs), timescale: 1000)
    let cgImage: CGImage
    do {
      cgImage = try imageGenerator.copyCGImage(at: targetTime, actualTime: nil)
    } catch {
      NSLog("couldn't generate thumbnail, error:%@", String(describing: error))
      return nil
    }

    switch format {
    case .jpeg:
      let fQuality = CGFloat(quality) * 0.01
      return UIImage(cgImage: cgImage).jpegData(compressionQuality: fQuality)
    case .png:
      return UIImage(cgImage: cgImage).pngData()
    case .webp:
      return VideoThumbKitWebPEncoder.encode(cgImage, quality: Int32(quality))
    }
  }
}
