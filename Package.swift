// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "fluent-sqlite-driver",
    products: [
        .library(name: "FluentSQLiteDriver", targets: ["FluentSQLiteDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", .branch("master")),
        .package(url: "https://github.com/vapor/nio-sqlite.git", .branch("master")),
        .package(url: "https://github.com/vapor/sql.git", .branch("master")),
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
