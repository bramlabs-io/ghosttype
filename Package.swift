// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "GhostType",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "GhostType",
            path: "Sources/GhostType",
            resources: [
                .copy("Resources/MenuBarIcon.png"),
                .copy("Resources/AppIcon.png")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Vision"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)
