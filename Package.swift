// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "typeclip",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(name: "TypeclipCore"),
        .executableTarget(
            name: "typeclip",
            dependencies: [
                "TypeclipCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "TypeclipCoreTests",
            dependencies: ["TypeclipCore", "typeclip"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
