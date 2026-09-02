#include "video_thumb_kit_plugin.h"

#include <flutter/plugin_registrar_windows.h>

#include <mfapi.h>
#include <mfidl.h>
#include <mfobjects.h>
#include <mfreadwrite.h>
#include <propvarutil.h>
#include <shlwapi.h>
#include <wincodec.h>
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <wrl/client.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <functional>
#include <memory>
#include <optional>
#include <sstream>
#include <string>
#include <vector>

#ifdef min
#undef min
#endif
#ifdef max
#undef max
#endif

namespace video_thumb_kit {

namespace {

using Microsoft::WRL::ComPtr;

std::string HResultToString(HRESULT hr) {
  std::ostringstream stream;
  stream << "HRESULT 0x" << std::hex << static_cast<unsigned long>(hr);
  return stream.str();
}

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }
  const int required_size = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
  if (required_size <= 1) {
    return std::wstring();
  }
  std::wstring result(required_size - 1, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, result.data(), required_size);
  return result;
}

std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) {
    return std::string();
  }
  const int required_size = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, nullptr, 0, nullptr, nullptr);
  if (required_size <= 1) {
    return std::string();
  }
  std::string result(required_size - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, result.data(), required_size, nullptr, nullptr);
  return result;
}

GUID FormatToContainerGuid(int format) {
  switch (format) {
    case 1:
      return GUID_ContainerFormatPng;
    case 2:
      // WebP is not available through all WIC setups; use PNG fallback.
      return GUID_ContainerFormatPng;
    case 0:
    default:
      return GUID_ContainerFormatJpeg;
  }
}

std::wstring OutputExtension(int format) {
  switch (format) {
    case 1:
      return L"png";
    case 2:
      return L"png";
    case 0:
    default:
      return L"jpg";
  }
}

std::optional<std::vector<uint8_t>> GenerateThumbnailBytes(
    const std::wstring& video_path,
    int format,
    int max_height,
    int max_width,
    int time_ms,
    int quality,
    std::string* error_message) {
  ComPtr<IMFAttributes> reader_attributes;
  HRESULT hr = MFCreateAttributes(&reader_attributes, 1);
  if (FAILED(hr)) {
    *error_message = "Cannot create source reader attributes: " + HResultToString(hr);
    return std::nullopt;
  }
  hr = reader_attributes->SetUINT32(MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING, TRUE);
  if (FAILED(hr)) {
    *error_message = "Cannot enable source reader video processing: " + HResultToString(hr);
    return std::nullopt;
  }

  ComPtr<IMFSourceReader> reader;
  hr = MFCreateSourceReaderFromURL(video_path.c_str(), reader_attributes.Get(), &reader);
  if (FAILED(hr)) {
    *error_message = "Cannot open video source: " + HResultToString(hr);
    return std::nullopt;
  }

  ComPtr<IMFMediaType> media_type;
  hr = MFCreateMediaType(&media_type);
  if (FAILED(hr)) {
    *error_message = "Cannot create media type: " + HResultToString(hr);
    return std::nullopt;
  }

  hr = media_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
  if (FAILED(hr)) {
    *error_message = "Cannot set major media type: " + HResultToString(hr);
    return std::nullopt;
  }
  hr = media_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32);
  if (FAILED(hr)) {
    *error_message = "Cannot set media subtype: " + HResultToString(hr);
    return std::nullopt;
  }

  hr = reader->SetCurrentMediaType(static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM), nullptr,
                                   media_type.Get());
  if (FAILED(hr)) {
    *error_message = "Cannot set current media type: " + HResultToString(hr);
    return std::nullopt;
  }

  PROPVARIANT seek_position;
  PropVariantInit(&seek_position);
  seek_position.vt = VT_I8;
  seek_position.hVal.QuadPart = static_cast<LONGLONG>(time_ms) * 10000;
  reader->SetCurrentPosition(GUID_NULL, seek_position);
  PropVariantClear(&seek_position);

  ComPtr<IMFSample> sample;
  DWORD stream_flags = 0;
  while (true) {
    hr = reader->ReadSample(static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM), 0, nullptr, &stream_flags,
                            nullptr, &sample);
    if (FAILED(hr)) {
      *error_message = "Cannot read video sample: " + HResultToString(hr);
      return std::nullopt;
    }
    if ((stream_flags & MF_SOURCE_READERF_ENDOFSTREAM) != 0) {
      *error_message = "Cannot extract frame at requested timestamp.";
      return std::nullopt;
    }
    if (sample) {
      break;
    }
  }

  ComPtr<IMFMediaBuffer> media_buffer;
  hr = sample->ConvertToContiguousBuffer(&media_buffer);
  if (FAILED(hr)) {
    *error_message = "Cannot access media buffer: " + HResultToString(hr);
    return std::nullopt;
  }

  BYTE* raw_data = nullptr;
  DWORD max_len = 0;
  DWORD current_len = 0;
  hr = media_buffer->Lock(&raw_data, &max_len, &current_len);
  if (FAILED(hr)) {
    *error_message = "Cannot lock media buffer: " + HResultToString(hr);
    return std::nullopt;
  }

  ComPtr<IMFMediaType> current_type;
  hr = reader->GetCurrentMediaType(static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM), &current_type);
  if (FAILED(hr)) {
    media_buffer->Unlock();
    *error_message = "Cannot get current media type: " + HResultToString(hr);
    return std::nullopt;
  }

  UINT32 frame_width = 0;
  UINT32 frame_height = 0;
  hr = MFGetAttributeSize(current_type.Get(), MF_MT_FRAME_SIZE, &frame_width, &frame_height);
  if (FAILED(hr) || frame_width == 0 || frame_height == 0) {
    media_buffer->Unlock();
    *error_message = "Cannot resolve frame size.";
    return std::nullopt;
  }

  const int src_width = static_cast<int>(frame_width);
  const int src_height = static_cast<int>(frame_height);
  const int src_stride = src_width * 4;

  int target_width = src_width;
  int target_height = src_height;
  if (max_width > 0 || max_height > 0) {
    if (max_width == 0) {
      target_height = max_height;
      target_width = static_cast<int>(std::round((static_cast<double>(src_width) / src_height) * target_height));
    } else if (max_height == 0) {
      target_width = max_width;
      target_height = static_cast<int>(std::round((static_cast<double>(src_height) / src_width) * target_width));
    } else {
      const double ratio = std::min(static_cast<double>(max_width) / src_width,
                                    static_cast<double>(max_height) / src_height);
      target_width = std::max(1, static_cast<int>(std::round(src_width * ratio)));
      target_height = std::max(1, static_cast<int>(std::round(src_height * ratio)));
    }
  }

  ComPtr<IWICImagingFactory> factory;
  hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory));
  if (FAILED(hr)) {
    media_buffer->Unlock();
    *error_message = "Cannot create WIC factory: " + HResultToString(hr);
    return std::nullopt;
  }

  ComPtr<IWICBitmap> bitmap;
  // MFVideoFormat_RGB32 is BGRX in memory on Windows; treating it as BGRA can
  // produce fully transparent thumbnails when alpha is zeroed.
  hr = factory->CreateBitmapFromMemory(src_width, src_height, GUID_WICPixelFormat32bppBGR, src_stride, current_len,
                                       raw_data, &bitmap);
  media_buffer->Unlock();
  if (FAILED(hr)) {
    *error_message = "Cannot create bitmap from frame: " + HResultToString(hr);
    return std::nullopt;
  }

  ComPtr<IWICBitmapSource> encode_source = bitmap;
  if (target_width != src_width || target_height != src_height) {
    ComPtr<IWICBitmapScaler> scaler;
    hr = factory->CreateBitmapScaler(&scaler);
    if (FAILED(hr)) {
      *error_message = "Cannot create bitmap scaler: " + HResultToString(hr);
      return std::nullopt;
    }
    hr = scaler->Initialize(bitmap.Get(), target_width, target_height, WICBitmapInterpolationModeFant);
    if (FAILED(hr)) {
      *error_message = "Cannot scale frame bitmap: " + HResultToString(hr);
      return std::nullopt;
    }
    encode_source = scaler;
  }

  GUID container_guid = FormatToContainerGuid(format);
  ComPtr<IWICBitmapEncoder> encoder;
  hr = factory->CreateEncoder(container_guid, nullptr, &encoder);
  if (FAILED(hr)) {
    *error_message = "Cannot create bitmap encoder: " + HResultToString(hr);
    return std::nullopt;
  }

  ComPtr<IStream> stream;
  hr = CreateStreamOnHGlobal(nullptr, TRUE, &stream);
  if (FAILED(hr)) {
    *error_message = "Cannot create output stream: " + HResultToString(hr);
    return std::nullopt;
  }

  hr = encoder->Initialize(stream.Get(), WICBitmapEncoderNoCache);
  if (FAILED(hr)) {
    *error_message = "Cannot initialize encoder: " + HResultToString(hr);
    return std::nullopt;
  }

  ComPtr<IWICBitmapFrameEncode> frame;
  ComPtr<IPropertyBag2> property_bag;
  hr = encoder->CreateNewFrame(&frame, &property_bag);
  if (FAILED(hr)) {
    *error_message = "Cannot create frame encoder: " + HResultToString(hr);
    return std::nullopt;
  }

  if (container_guid == GUID_ContainerFormatJpeg && property_bag != nullptr) {
    PROPBAG2 option = {};
    option.pstrName = const_cast<LPOLESTR>(L"ImageQuality");
    VARIANT value;
    VariantInit(&value);
    value.vt = VT_R4;
    value.fltVal = static_cast<float>(std::clamp(quality, 0, 100)) / 100.0f;
    property_bag->Write(1, &option, &value);
    VariantClear(&value);
  }

  hr = frame->Initialize(property_bag.Get());
  if (FAILED(hr)) {
    *error_message = "Cannot initialize output frame: " + HResultToString(hr);
    return std::nullopt;
  }

  hr = frame->SetSize(target_width, target_height);
  if (FAILED(hr)) {
    *error_message = "Cannot set output size: " + HResultToString(hr);
    return std::nullopt;
  }

  WICPixelFormatGUID pixel_format = GUID_WICPixelFormat24bppBGR;
  hr = frame->SetPixelFormat(&pixel_format);
  if (FAILED(hr)) {
    *error_message = "Cannot set pixel format: " + HResultToString(hr);
    return std::nullopt;
  }

  hr = frame->WriteSource(encode_source.Get(), nullptr);
  if (FAILED(hr)) {
    *error_message = "Cannot encode image frame: " + HResultToString(hr);
    return std::nullopt;
  }

  hr = frame->Commit();
  if (FAILED(hr)) {
    *error_message = "Cannot commit image frame: " + HResultToString(hr);
    return std::nullopt;
  }
  hr = encoder->Commit();
  if (FAILED(hr)) {
    *error_message = "Cannot commit image encoder: " + HResultToString(hr);
    return std::nullopt;
  }

  HGLOBAL global_memory = nullptr;
  hr = GetHGlobalFromStream(stream.Get(), &global_memory);
  if (FAILED(hr) || global_memory == nullptr) {
    *error_message = "Cannot extract encoded image bytes.";
    return std::nullopt;
  }

  const SIZE_T size = GlobalSize(global_memory);
  if (size == 0) {
    *error_message = "Encoded image is empty.";
    return std::nullopt;
  }

  void* ptr = GlobalLock(global_memory);
  if (ptr == nullptr) {
    *error_message = "Cannot read encoded image bytes.";
    return std::nullopt;
  }
  std::vector<uint8_t> output(size);
  memcpy(output.data(), ptr, size);
  GlobalUnlock(global_memory);
  return output;
}

std::wstring BuildOutputPath(const std::wstring& video_path, const std::optional<std::string>& requested_utf8, int format) {
  const auto extension = OutputExtension(format);
  if (requested_utf8.has_value() && !requested_utf8->empty()) {
    std::filesystem::path requested(Utf8ToWide(*requested_utf8));
    if (std::filesystem::is_directory(requested)) {
      std::filesystem::path file_name = std::filesystem::path(video_path).stem();
      if (file_name.empty()) {
        file_name = L"thumbnail";
      }
      return (requested / file_name).replace_extension(extension).wstring();
    }
    if (requested.has_extension()) {
      return requested.wstring();
    }
    return requested.replace_extension(extension).wstring();
  }

  std::filesystem::path temp_dir = std::filesystem::temp_directory_path();
  std::filesystem::path base_name = std::filesystem::path(video_path).stem();
  if (base_name.empty()) {
    base_name = L"thumbnail";
  }
  return (temp_dir / base_name).replace_extension(extension).wstring();
}

}  // namespace

VideoThumbKitPlugin::VideoThumbKitPlugin() { MFStartup(MF_VERSION); }

VideoThumbKitPlugin::~VideoThumbKitPlugin() { MFShutdown(); }

void VideoThumbKitPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<VideoThumbKitPlugin>();

  VideoThumbKitHostApi::SetUp(registrar->messenger(), plugin.get());

  registrar->AddPlugin(std::move(plugin));
}

void VideoThumbKitPlugin::GenerateThumbnailFile(
    const ThumbnailRequest& request,
    std::function<void(ErrorOr<std::optional<std::string>> reply)> result) {
  const std::wstring video_path = Utf8ToWide(request.video());
  const int format = static_cast<int>(request.image_format());
  const int maxh = static_cast<int>(request.max_height());
  const int maxw = static_cast<int>(request.max_width());
  const int time_ms = static_cast<int>(request.time_ms());
  const int quality = static_cast<int>(request.quality());

  std::string error_message;
  const auto bytes =
      GenerateThumbnailBytes(video_path, format, maxh, maxw, time_ms, quality, &error_message);
  if (!bytes.has_value()) {
    result(FlutterError("thumbnail_error", error_message));
    return;
  }

  const std::optional<std::string> path_arg =
      request.path() != nullptr ? std::optional<std::string>(*request.path()) : std::nullopt;
  const std::wstring output_path = BuildOutputPath(video_path, path_arg, format);
  std::error_code ec;
  std::filesystem::create_directories(std::filesystem::path(output_path).parent_path(), ec);
  FILE* file = nullptr;
  _wfopen_s(&file, output_path.c_str(), L"wb");
  if (file == nullptr) {
    result(FlutterError("thumbnail_error", "Cannot open output file for writing."));
    return;
  }
  fwrite(bytes->data(), sizeof(uint8_t), bytes->size(), file);
  fclose(file);
  result(std::optional<std::string>(WideToUtf8(output_path)));
}

void VideoThumbKitPlugin::GenerateThumbnailData(
    const ThumbnailRequest& request,
    std::function<void(ErrorOr<std::optional<std::vector<uint8_t>>> reply)> result) {
  const std::wstring video_path = Utf8ToWide(request.video());
  const int format = static_cast<int>(request.image_format());
  const int maxh = static_cast<int>(request.max_height());
  const int maxw = static_cast<int>(request.max_width());
  const int time_ms = static_cast<int>(request.time_ms());
  const int quality = static_cast<int>(request.quality());

  std::string error_message;
  const auto bytes =
      GenerateThumbnailBytes(video_path, format, maxh, maxw, time_ms, quality, &error_message);
  if (!bytes.has_value()) {
    result(FlutterError("thumbnail_error", error_message));
    return;
  }

  result(std::optional<std::vector<uint8_t>>(*bytes));
}

}  // namespace video_thumb_kit
