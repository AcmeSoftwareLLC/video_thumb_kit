// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "video_thumb_kit",
  platforms: [
    .iOS("13.0"),
    .macOS("10.15"),
  ],
  products: [
    .library(name: "video-thumb-kit", targets: ["video_thumb_kit"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
    .package(url: "https://github.com/SDWebImage/libwebp-Xcode.git", from: "1.3.2"),
  ],
  targets: [
    .target(
      name: "video_thumb_kit",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        .target(name: "video_thumb_kit_webp", condition: .when(platforms: [.iOS])),
      ]
    ),
    .target(
      name: "video_thumb_kit_webp",
      dependencies: [
        .product(name: "libwebp", package: "libwebp-Xcode")
      ],
      publicHeadersPath: "include"
    ),
  ]
)
