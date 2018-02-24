// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Fluent",
    products: [
        .library(name: "FluentSQLite", targets: ["FluentSQLite"]),
    ],
    dependencies: [
        // ⏱ Promises and reactive-streams in Swift built for high-performance and scalability.
        .package(url: "https://github.com/vapor/async.git", from: "1.0.0-rc"),

        // 🌎 Utility package containing tools for byte manipulation, Codable, OS APIs, and debugging.
        .package(url: "https://github.com/vapor/core.git", from: "3.0.0-rc"),

        // ✳️ Swift ORM framework (queries, models, and relations) for building NoSQL and SQL database integrations.
        .package(url: "https://github.com/vapor/fluent.git", from: "3.0.0-rc"),

        // 📦 Dependency injection / inversion of control framework.
        .package(url: "https://github.com/vapor/service.git", from: "1.0.0-rc"),

        // 🔵 SQLite 3 wrapper for Swift
        .package(url: "https://github.com/vapor/sqlite.git", from: "3.0.0-rc"),
    ],
    targets: [
        .target(name: "FluentSQLite", dependencies: ["Fluent", "FluentSQL", "Service", "SQLite"]),
        .testTarget(name: "FluentSQLiteTests", dependencies: ["FluentBenchmark", "FluentSQLite", "SQLite"]),
    ]
)
