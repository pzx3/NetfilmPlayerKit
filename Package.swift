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
    ],
    targets: [
        .target(
            name: "NetfilmPlayer",
            dependencies: [
            ],
            path: "Source",
            resources: [
                .process("Pod_Asset_NetfilmPlayer.xcassets")
            ]
        )
    ]
)
