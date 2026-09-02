import AVFoundation
import Cocoa
import FlutterMacOS
import QuickLookThumbnailing

public class VideoThumbKitPlugin: NSObject, FlutterPlugin, VideoThumbKitHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = VideoThumbKitPlugin()
    VideoThumbKitHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  func generateThumbnailData(request: ThumbnailRequest) async throws -> FlutterStandardTypedData? {
    let data = try await Self.performInBackground {
      try Self.buildThumbnail(request: request)
    }
    return FlutterStandardTypedData(bytes: data)
  }

  func generateThumbnailFile(request: ThumbnailRequest) async throws -> String? {
    try await Self.performInBackground {
      let data = try Self.buildThumbnail(request: request)
      let outputPath = try Self.resolveOutputPath(
        originalVideo: request.video,
        requestedPath: request.path,
        format: request.imageFormat.rawValue)
      try data.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
      return outputPath
    }
  }

  private static func performInBackground<T>(_ work: @escaping () throws -> T) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          continuation.resume(returning: try work())
        } catch let error as PigeonError {
          continuation.resume(throwing: error)
        } catch {
          continuation.resume(
            throwing: PigeonError(code: "thumbnail_error", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private static func buildThumbnail(request: ThumbnailRequest) throws -> Data {
    let url: URL
    if request.video.hasPrefix("file://") {
      url = URL(fileURLWithPath: String(request.video.dropFirst(7)))
    } else if request.video.hasPrefix("/") {
      url = URL(fileURLWithPath: request.video)
    } else {
      guard let remoteURL = URL(string: request.video) else {
        throw PigeonError(code: "invalid_url", message: "Invalid video URL", details: nil)
      }
      url = remoteURL
    }

    var didAccessSecurityScopedResource = false
    if url.isFileURL {
      didAccessSecurityScopedResource = url.startAccessingSecurityScopedResource()
    }
    defer {
      if didAccessSecurityScopedResource {
        url.stopAccessingSecurityScopedResource()
      }
    }

    return try generateThumbnail(
      url: url,
      headers: request.headers,
      format: request.imageFormat.rawValue,
      maxHeight: Int(request.maxHeight),
      maxWidth: Int(request.maxWidth),
      timeMs: Int(request.timeMs),
      quality: Int(request.quality))
  }

  private static func resolveOutputPath(
    originalVideo: String,
    requestedPath: String?,
    format: Int
  ) throws -> String {
    let ext = fileExtension(for: format)
    if let requestedPath, !requestedPath.isEmpty {
      if URL(fileURLWithPath: requestedPath).pathExtension.lowercased() == ext {
        return requestedPath
      }

      var isDir: ObjCBool = false
      if FileManager.default.fileExists(atPath: requestedPath, isDirectory: &isDir), isDir.boolValue {
        let fileName = "\(UUID().uuidString).\(ext)"
        return URL(fileURLWithPath: requestedPath).appendingPathComponent(fileName).path
      }

      return requestedPath + "." + ext
    }

    // On macOS sandbox, writing near user-selected files can fail.
    // Save generated thumbnails in app cache by default.
    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    return cacheDir.appendingPathComponent("\(UUID().uuidString).\(ext)").path
  }

  private static func fileExtension(for format: Int) -> String {
    switch format {
    case 0:
      return "jpg"
    case 1:
      return "png"
    case 2:
      return "webp"
    default:
      return "jpg"
    }
  }

  private static func imageData(from cgImage: CGImage, format: Int, quality: Int) throws -> Data {
    let rep = NSBitmapImageRep(cgImage: cgImage)
    switch format {
    case 1:
      if let data = rep.representation(using: .png, properties: [:]) {
        return data
      }
    case 2:
      // NSBitmapImageRep.FileType.webP is not available on all SDKs/toolchains,
      // so fall back to PNG for compatibility.
      if let data = rep.representation(using: .png, properties: [:]) {
        return data
      }
    default:
      if let data = rep.representation(using: .jpeg, properties: [.compressionFactor: qualityFactor(quality)]) {
        return data
      }
    }
    throw NSError(
      domain: "video_thumb_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Failed to encode thumbnail image"])
  }

  private static func qualityFactor(_ quality: Int) -> CGFloat {
    return CGFloat(max(0, min(quality, 100))) / 100.0
  }

  private static func generateThumbnail(
    url: URL,
    headers: [String: String]?,
    format: Int,
    maxHeight: Int,
    maxWidth: Int,
    timeMs: Int,
    quality: Int
  ) throws -> Data {
    var options: [String: Any] = [:]
    if let headers {
      options["AVURLAssetHTTPHeaderFieldsKey"] = headers
    }

    let asset = AVURLAsset(url: url, options: options.isEmpty ? nil : options)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    imageGenerator.requestedTimeToleranceBefore = .zero
    imageGenerator.requestedTimeToleranceAfter = CMTime(value: 100, timescale: 1000)
    if maxWidth > 0 && maxHeight > 0 {
      imageGenerator.maximumSize = CGSize(width: maxWidth, height: maxHeight)
    }

    let targetTime = CMTime(value: Int64(timeMs), timescale: 1000)
    var actualTime = CMTime.zero
    do {
      let cgImage = try imageGenerator.copyCGImage(at: targetTime, actualTime: &actualTime)
      return try imageData(from: cgImage, format: format, quality: quality)
    } catch let avError {
      if url.isFileURL {
        do {
          if let fallback = try quickLookThumbnailData(
            fileURL: url,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            format: format,
            quality: quality)
          {
            return fallback
          }
        } catch {
          throw thumbnailOpenError(for: url, underlyingError: error)
        }
      }
      throw thumbnailOpenError(for: url, underlyingError: avError)
    }
  }

  private static func quickLookThumbnailData(
    fileURL: URL,
    maxWidth: Int,
    maxHeight: Int,
    format: Int,
    quality: Int
  ) throws -> Data? {
    if #available(macOS 10.15, *) {
      let width = max(1, maxWidth == 0 ? 512 : maxWidth)
      let height = max(1, maxHeight == 0 ? 512 : maxHeight)
      let request = QLThumbnailGenerator.Request(
        fileAt: fileURL,
        size: CGSize(width: width, height: height),
        scale: 1.0,
        representationTypes: .thumbnail)

      let semaphore = DispatchSemaphore(value: 0)
      var generatedData: Data?
      var generatedError: Error?

      QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { thumbnail, error in
        defer { semaphore.signal() }
        if let error {
          generatedError = error
          return
        }
        guard let cgImage = thumbnail?.cgImage else {
          return
        }
        do {
          generatedData = try imageData(from: cgImage, format: format, quality: quality)
        } catch {
          generatedError = error
        }
      }

      _ = semaphore.wait(timeout: .now() + 5)

      if let generatedData {
        return generatedData
      }
      if let generatedError {
        throw generatedError
      }
    }
    return nil
  }

  private static func thumbnailOpenError(for url: URL, underlyingError: Error) -> NSError {
    let ext = url.pathExtension.lowercased()
    var message = "Cannot open video for thumbnail generation on macOS."
    if ext == "webm" {
      message = "This .webm file codec is not supported by macOS thumbnail providers on this machine."
    }
    return NSError(
      domain: "video_thumb_kit",
      code: 2,
      userInfo: [
        NSLocalizedDescriptionKey: message,
        NSUnderlyingErrorKey: underlyingError
      ])
  }
}
