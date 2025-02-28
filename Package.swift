// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "NetfilmPlayer",
    platforms: [
        .iOS(.v13) // Minimum supported iOS version
    ],
    products: [
        .library(
            name: "NetfilmPlayer",
            targets: ["NetfilmPlayer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.0"),
        .package(url: "https://github.com/ninjaprox/NVActivityIndicatorView.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "NetfilmPlayer",
            dependencies: [
                "SnapKit",
                "NVActivityIndicatorView"
            ],
            path: "Source",
            resources: [
                .process("Pod_Asset_NetfilmPlayer.xcassets")
            ]
        )
    ]
)
