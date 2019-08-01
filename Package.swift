// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "fluent-sqlite-driver",
    products: [
        .library(name: "FluentSQLiteDriver", targets: ["FluentSQLiteDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.0.0-alpha.2"),
        .package(url: "https://github.com/vapor/sqlite-kit.git", from: "4.0.0-alpha"),
    ],
    targets: [
        .target(name: "FluentSQLiteDriver", dependencies: [
            "FluentKit",
            "FluentSQL",
            "SQLiteKit",
        ]),
        .testTarget(name: "FluentSQLiteDriverTests", dependencies: ["FluentBenchmark", "FluentSQLiteDriver"]),
    ]
)
