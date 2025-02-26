// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "NetfilmPlayer",
    platforms: [
        .iOS(.v13) // Minimum supported iOS version
    ],
    products: [
        // Defines the library that will be available to other projects
        .library(
            name: "NetfilmPlayer",
            targets: ["NetfilmPlayer"]
        ),
    ],
    dependencies: [
        // Add external dependencies if needed in the future
    ],
    targets: [
        .target(
            name: "NetfilmPlayer",
            dependencies: [],
            path: "Sources" // Ensure this matches your source folder structure
        )
    ]
)
