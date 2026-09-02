#import "VideoThumbKitWebPEncoder.h"

#if __has_include("webp/decode.h") && __has_include("webp/encode.h") && __has_include("webp/demux.h") && __has_include("webp/mux.h")
#import "webp/decode.h"
#import "webp/encode.h"
#import "webp/demux.h"
#import "webp/mux.h"
#elif __has_include(<libwebp/decode.h>) && __has_include(<libwebp/encode.h>) && __has_include(<libwebp/demux.h>) && __has_include(<libwebp/mux.h>)
#import <libwebp/decode.h>
#import <libwebp/encode.h>
#import <libwebp/demux.h>
#import <libwebp/mux.h>
#endif

@implementation VideoThumbKitWebPEncoder

+ (nullable NSData *)encodeImage:(CGImageRef)cgImage quality:(int)quality {
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(cgImage);
  if (CGColorSpaceGetModel(colorSpace) != kCGColorSpaceModelRGB) {
    return nil;
  }
  CGImageAlphaInfo ainfo = CGImageGetAlphaInfo(cgImage);
  CGBitmapInfo binfo = CGImageGetBitmapInfo(cgImage);

  CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
  CFDataRef imageData = CGDataProviderCopyData(dataProvider);
  UInt8 *rawData = (UInt8 *)CFDataGetBytePtr(imageData);

  int width = (int)CGImageGetWidth(cgImage);
  int height = (int)CGImageGetHeight(cgImage);
  int stride = (int)CGImageGetBytesPerRow(cgImage);
  size_t ret_size = 0;
  uint8_t *output = NULL;

  // preprocess the data for libwebp
  if (ainfo == kCGImageAlphaPremultipliedFirst || ainfo == kCGImageAlphaNoneSkipFirst) {
    if ((binfo & kCGBitmapByteOrderMask) == kCGBitmapByteOrder32Little) {
      // Little-endian (iPhone)
      if (quality == 100)
        ret_size = WebPEncodeLosslessBGRA(rawData, width, height, stride, &output);
      else
        ret_size = WebPEncodeBGRA(rawData, width, height, stride, (float)quality, &output);
    } else if ((binfo & kCGBitmapByteOrderMask) == kCGBitmapByteOrder32Big) {
      // Big-endian (iPhone Simulator)
      for (int y = 0; y < height; y++) {
        uint32_t *p = (uint32_t *)((uint8_t *)(rawData + y * stride));
        for (int x = 0; x < width; x++, p++) {
          uint32_t u = *p;
          *p = ((u << 24) & 0xFF000000) | ((u >> 8) & 0x00FFFFFF);
        }
      }
      if (quality == 100)
        ret_size = WebPEncodeLosslessRGBA(rawData, width, height, stride, &output);
      else
        ret_size = WebPEncodeRGBA(rawData, width, height, stride, (float)quality, &output);
    }
  } else {
    NSLog(@"Sorry, don't support this CGImageAlphaInfo: %d", (int)binfo);
  }
  CGDataProviderRelease(dataProvider);
  CFRelease(imageData);
  CGColorSpaceRelease(colorSpace);

  if (ret_size == 0) {
    return nil;
  }
  NSData *data = [NSData dataWithBytes:(const void *)output length:ret_size];
  WebPFree(output);
  return data;
}

@end
