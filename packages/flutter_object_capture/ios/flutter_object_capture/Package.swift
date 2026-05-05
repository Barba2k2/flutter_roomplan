// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_object_capture",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        // The Flutter tool resolves the SwiftPM product whose name matches the
        // dashed form of the plugin name.
        .library(name: "flutter-object-capture", targets: ["flutter_object_capture"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_object_capture",
            dependencies: [],
            resources: []
        )
    ]
)
