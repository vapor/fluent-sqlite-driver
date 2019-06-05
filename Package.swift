// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "fluent-sqlite-driver",
    products: [
        .library(name: "FluentSQLiteDriver", targets: ["FluentSQLiteDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", .branch("alpha")),
        .package(url: "https://github.com/vapor/nio-sqlite.git", .branch("master")),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.0.0-alpha"),
        .package(url: "https://github.com/vapor/nio-kit.git", .branch("master")),
    ],
    targets: [
        .target(name: "FluentSQLiteDriver", dependencies: [
            "FluentKit",
            "FluentSQL",
            "NIOKit",
            "NIOSQLite",
            "SQLKit"
        ]),
        .testTarget(name: "FluentSQLiteDriverTests", dependencies: ["FluentBenchmark", "FluentSQLiteDriver"]),
    ]
)
