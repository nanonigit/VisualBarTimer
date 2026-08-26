// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VisualBarTimer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "VisualBarTimer",
            targets: ["VisualBarTimer"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "VisualBarTimer",
            dependencies: [],
            path: "Sources/VisualBarTimer"
        )
    ]
)
