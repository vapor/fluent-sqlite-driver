// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "fluent-sqlite-driver",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "FluentSQLiteDriver", targets: ["FluentSQLiteDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.45.0"),
        .package(url: "https://github.com/vapor/sqlite-kit.git", from: "4.4.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
    ],
    targets: [
        .target(name: "FluentSQLiteDriver", dependencies: [
            .product(name: "FluentKit", package: "fluent-kit"),
            .product(name: "FluentSQL", package: "fluent-kit"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "SQLiteKit", package: "sqlite-kit"),
        ]),
        .testTarget(name: "FluentSQLiteDriverTests", dependencies: [
            .product(name: "FluentBenchmark", package: "fluent-kit"),
            .target(name: "FluentSQLiteDriver"),
        ]),
    ]
)
