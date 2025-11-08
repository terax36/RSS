// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "KitsuneReader",
    platforms: [
        .iOS(.v18),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "KitsuneReader",
            targets: ["KitsuneReader"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nmdias/FeedKit.git", exact: "10.1.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", .upToNextMajor(from: "2.6.0")),
        .package(url: "https://github.com/kean/Nuke.git", .upToNextMajor(from: "12.0.0")),
    ],
    targets: [
        .target(
            name: "KitsuneReader",
            dependencies: [
                "FeedKit",
                "SwiftSoup",
                "Nuke"
            ],
            path: "KitsuneReader",
            resources: [
                .process("Assets.xcassets"),
                .process("Models/KitsuneReader.xcdatamodeld"),
                .process("Samples/feeds.opml"),
                .process("Samples/sample.html"),
                .process("Web/DarkCSSDefaults.css")
            ]
        ),
        .testTarget(
            name: "KitsuneReaderTests",
            dependencies: ["KitsuneReader"],
            path: "KitsuneReaderTests"
        ),
    ]
)
