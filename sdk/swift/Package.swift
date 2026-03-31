// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SiloKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "SiloKit", targets: ["SiloKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
    ],
    targets: [
        .target(
            name: "SiloKit",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .testTarget(
            name: "SiloKitTests",
            dependencies: ["SiloKit"]
        ),
    ]
)
