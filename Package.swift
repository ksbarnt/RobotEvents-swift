// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RobotEvents",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
    ],
    products: [
        .library(name: "RobotEvents", targets: ["RobotEvents"]),
    ],
    targets: [
        .target(
            name: "RobotEvents",
            path: "Sources/RobotEvents"
        ),
        .testTarget(
            name: "RobotEventsTests",
            dependencies: ["RobotEvents"],
            path: "Tests/RobotEventsTests"
        ),
    ]
)
