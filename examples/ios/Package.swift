// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SiloExample",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .executable(name: "silo-example", targets: ["SiloExample"]),
    ],
    dependencies: [
        .package(path: "../../sdk/swift"),
    ],
    targets: [
        .executableTarget(
            name: "SiloExample",
            dependencies: [.product(name: "SiloKit", package: "swift")],
            path: "Sources"
        ),
    ]
)
