// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mobile",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AnonyCore",
            targets: ["AnonyCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AnonyCore",
            dependencies: [],
            path: "Sources/AnonyCore"
        ),
        .testTarget(
            name: "AnonyCoreTests",
            dependencies: ["AnonyCore"],
            path: "Tests/AnonyCoreTests"
        )
    ]
)
