// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MetadataRandomizerMac",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MetadataRandomizerMac",
            path: "Sources"
        )
    ]
)
