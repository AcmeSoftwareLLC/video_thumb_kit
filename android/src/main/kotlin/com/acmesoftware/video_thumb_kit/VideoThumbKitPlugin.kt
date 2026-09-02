package com.acmesoftware.video_thumb_kit

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** VideoThumbKitPlugin */
class VideoThumbKitPlugin : FlutterPlugin, VideoThumbKitHostApi {
  private lateinit var context: Context

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    VideoThumbKitHostApi.setUp(binding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    VideoThumbKitHostApi.setUp(binding.binaryMessenger, null)
  }

  override suspend fun generateThumbnailFile(request: ThumbnailRequest): String? =
      withContext(Dispatchers.IO) {
        try {
          buildThumbnailFile(
              request.video,
              request.headers,
              request.path,
              request.imageFormat,
              request.maxHeight.toInt(),
              request.maxWidth.toInt(),
              request.timeMs.toInt(),
              request.quality.toInt())
        } catch (e: Exception) {
          throw FlutterError("exception", e.message)
        }
      }

  override suspend fun generateThumbnailData(request: ThumbnailRequest): ByteArray? =
      withContext(Dispatchers.IO) {
        try {
          buildThumbnailData(
              request.video,
              request.headers,
              request.imageFormat,
              request.maxHeight.toInt(),
              request.maxWidth.toInt(),
              request.timeMs.toInt(),
              request.quality.toInt())
        } catch (e: Exception) {
          throw FlutterError("exception", e.message)
        }
      }

  private fun buildThumbnailData(
      vidPath: String,
      headers: Map<String, String>?,
      format: ImageFormat,
      maxh: Int,
      maxw: Int,
      timeMs: Int,
      quality: Int
  ): ByteArray {
    val bitmap =
        createVideoThumbnail(vidPath, headers, maxh, maxw, timeMs)
            ?: throw NullPointerException("Failed to create video thumbnail")

    val stream = ByteArrayOutputStream()
    bitmap.compress(formatToCompressFormat(format), quality, stream)
    bitmap.recycle()
    return stream.toByteArray()
  }

  private fun buildThumbnailFile(
      vidPath: String,
      headers: Map<String, String>?,
      requestedPath: String?,
      format: ImageFormat,
      maxh: Int,
      maxw: Int,
      timeMs: Int,
      quality: Int
  ): String {
    val bytes = buildThumbnailData(vidPath, headers, format, maxh, maxw, timeMs, quality)
    val ext = formatExt(format)
    val i = vidPath.lastIndexOf(".")
    var fullpath = vidPath.substring(0, i + 1) + ext
    val isLocalFile = vidPath.startsWith("/") || vidPath.startsWith("file://")

    val path = requestedPath ?: if (!isLocalFile) context.cacheDir.absolutePath else null

    if (path != null) {
      fullpath =
          if (path.endsWith(ext)) {
            path
          } else {
            // try to save to same folder as the vidPath
            val j = fullpath.lastIndexOf("/")
            if (path.endsWith("/")) {
              path + fullpath.substring(j + 1)
            } else {
              path + fullpath.substring(j)
            }
          }
    }

    try {
      FileOutputStream(fullpath).use { it.write(bytes) }
      Log.d(TAG, "buildThumbnailFile( written:${bytes.size} )")
    } catch (e: IOException) {
      Log.e(TAG, "Error writing thumbnail file", e)
      throw RuntimeException("Failed to write thumbnail file", e)
    }
    return fullpath
  }

  /**
   * Create a video thumbnail for a video. May return null if the video is corrupt or the format
   * is not supported.
   *
   * @param video the URI of video
   * @param headers optional headers for network requests
   * @param targetHIn the max height of the thumbnail
   * @param targetWIn the max width of the thumbnail
   * @param timeMs the time in milliseconds to extract the frame
   * @return the thumbnail bitmap or null if extraction fails
   */
  @Suppress("DEPRECATION")
  private fun createVideoThumbnail(
      video: String,
      headers: Map<String, String>?,
      targetHIn: Int,
      targetWIn: Int,
      timeMs: Int
  ): Bitmap? {
    var bitmap: Bitmap? = null
    var targetH = targetHIn
    var targetW = targetWIn
    val retriever = MediaMetadataRetriever()
    try {
      when {
        video.startsWith("/") -> setDataSource(video, retriever)
        video.startsWith("file://") -> setDataSource(video.substring(7), retriever)
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> retriever.setDataSource(video)
        else -> retriever.setDataSource(video, headers ?: HashMap())
      }

      bitmap =
          if (targetH != 0 || targetW != 0) {
            if (Build.VERSION.SDK_INT >= 27 && targetH != 0 && targetW != 0) {
              retriever.getScaledFrameAtTime(
                  timeMs * 1000L, MediaMetadataRetriever.OPTION_CLOSEST, targetW, targetH)
            } else {
              var frame =
                  retriever.getFrameAtTime(timeMs * 1000L, MediaMetadataRetriever.OPTION_CLOSEST)
              if (frame != null) {
                val width = frame.width
                val height = frame.height
                if (targetW == 0) {
                  targetW = Math.round((targetH.toFloat() / height) * width)
                }
                if (targetH == 0) {
                  targetH = Math.round((targetW.toFloat() / width) * height)
                }
                Log.d(TAG, "original w:$width, h:$height => $targetW, $targetH")
                frame = Bitmap.createScaledBitmap(frame, targetW, targetH, true)
              }
              frame
            }
          } else {
            retriever.getFrameAtTime(timeMs * 1000L, MediaMetadataRetriever.OPTION_CLOSEST)
          }
    } catch (ex: IllegalArgumentException) {
      Log.e(TAG, "Illegal argument when creating video thumbnail", ex)
    } catch (ex: RuntimeException) {
      Log.e(TAG, "Runtime exception when creating video thumbnail", ex)
    } catch (ex: IOException) {
      Log.e(TAG, "IO exception when creating video thumbnail", ex)
    } finally {
      try {
        retriever.release()
      } catch (ex: RuntimeException) {
        Log.e(TAG, "Error releasing MediaMetadataRetriever", ex)
      } catch (ex: IOException) {
        Log.e(TAG, "Error releasing MediaMetadataRetriever", ex)
      }
    }

    return bitmap
  }

  companion object {
    private const val TAG = "ThumbnailPlugin"

    private fun setDataSource(video: String, retriever: MediaMetadataRetriever) {
      val videoFile = File(video)
      if (!videoFile.exists()) {
        throw IOException("Video file does not exist: $video")
      }
      FileInputStream(videoFile).use { retriever.setDataSource(it.fd) }
    }

    private fun formatToCompressFormat(format: ImageFormat): Bitmap.CompressFormat =
        when (format) {
          ImageFormat.PNG -> Bitmap.CompressFormat.PNG
          ImageFormat.WEBP ->
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Bitmap.CompressFormat.WEBP_LOSSY
              } else {
                @Suppress("DEPRECATION") Bitmap.CompressFormat.WEBP
              }
          ImageFormat.JPEG -> Bitmap.CompressFormat.JPEG
        }

    private fun formatExt(format: ImageFormat): String =
        when (format) {
          ImageFormat.PNG -> "png"
          ImageFormat.WEBP -> "webp"
          ImageFormat.JPEG -> "jpg"
        }
  }
}
