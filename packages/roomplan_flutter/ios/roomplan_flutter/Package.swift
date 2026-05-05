// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "roomplan_flutter",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        // The Flutter tool resolves the SwiftPM product whose name matches the
        // dashed form of the plugin name.
        .library(name: "roomplan-flutter", targets: ["roomplan_flutter"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "roomplan_flutter",
            dependencies: [],
            resources: []
        )
    ]
)
