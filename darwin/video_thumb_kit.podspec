#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'video_thumb_kit'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter package for generating thumbnails from videos.'
  s.description      = <<-DESC
A fast, cross-platform Flutter plugin for generating video thumbnails.
                       DESC
  s.homepage         = 'https://acmesoftware.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Acme Software' => 'email@example.com' }
  s.source           = { :path => '.' }

  s.source_files            = 'video_thumb_kit/Sources/video_thumb_kit/**/*.swift'
  s.ios.source_files         = 'video_thumb_kit/Sources/video_thumb_kit/**/*.swift',
                                'video_thumb_kit/Sources/video_thumb_kit_webp/**/*.{h,m}'
  s.ios.public_header_files = 'video_thumb_kit/Sources/video_thumb_kit_webp/include/*.h'
  s.ios.pod_target_xcconfig = {
    'USER_HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_ROOT}/libwebp/**'
  }
  s.ios.dependency 'libwebp'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.swift_version = '5.0'
end
