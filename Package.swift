// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "fluent-sqlite-driver",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(name: "FluentSQLiteDriver", targets: ["FluentSQLiteDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", .branch("composite-primary-key-models")),
        .package(url: "https://github.com/vapor/sqlite-kit.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
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
