#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Encodes a `CGImage` to WebP using libwebp.
///
/// Kept as an Objective-C wrapper (rather than calling libwebp's C API
/// directly from Swift) because Swift framework targets cannot use bridging
/// headers, and this pod is built as a framework.
@interface VideoThumbKitWebPEncoder : NSObject

+ (nullable NSData *)encodeImage:(CGImageRef)image quality:(int)quality
    NS_SWIFT_NAME(encode(_:quality:));

@end

NS_ASSUME_NONNULL_END
