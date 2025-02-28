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
