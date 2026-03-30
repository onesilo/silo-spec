// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SiloReader",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "SiloReader", targets: ["SiloReader"]),
        .executable(name: "silo-reader", targets: ["SiloReaderCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/GRDB.swift.git", from: "6.24.0"),
    ],
    targets: [
        .target(
            name: "SiloReader",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")]
        ),
        .executableTarget(
            name: "SiloReaderCLI",
            dependencies: ["SiloReader"]
        ),
    ]
)
