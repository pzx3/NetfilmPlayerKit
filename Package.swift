// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "NetfilmPlayerKit",
    platforms: [
        .iOS(.v13) // Minimum supported iOS version
    ],
    products: [
        .library(
            name: "NetfilmPlayerKit",
            targets: ["NetfilmPlayerKit"]
        ),
    ],
    dependencies: [
        // إضافة SnapKit
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.0"),
        // إضافة NVActivityIndicatorView
        .package(url: "https://github.com/ninjaprox/NVActivityIndicatorView.git", from: "4.7.0"),
    ],
    targets: [
        .target(
            name: "NetfilmPlayerKit",
            dependencies: [
                "SnapKit", // إضافة SnapKit كمكتبة تابعة
                "NVActivityIndicatorView" // إضافة NVActivityIndicatorView كمكتبة تابعة
            ],
            path: "Source",
            resources: [
                .process("Pod_Asset_NetfilmPlayer.xcassets")
            ]
        )
    ]
)
