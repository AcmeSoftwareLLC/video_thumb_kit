Pod::Spec.new do |s|
  s.name             = 'video_thumb_kit'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter package for generating thumbnails from videos.'
  s.description      = <<-DESC
Generate thumbnails from video files on macOS.
                       DESC
  s.homepage         = 'https://github.com/AcmeSoftwareLLC/video_thumb_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.swift_version = '5.0'
end
