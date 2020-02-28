extension DatabaseConfigurationFactory {
    public static func sqlite(
        _ configuration: SQLiteConfiguration = .init(storage: .memory),
        maxConnectionsPerEventLoop: Int = 1
    ) -> Self {
        return .init {
            FluentSQLiteConfiguration(
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                middleware: []
            )
        }
    }
}

struct FluentSQLiteConfiguration: DatabaseConfiguration {
    let configuration: SQLiteConfiguration
    let maxConnectionsPerEventLoop: Int
    var middleware: [AnyModelMiddleware]

    func makeDriver(for databases: Databases) -> DatabaseDriver {
        let db = SQLiteConnectionSource(
            configuration: configuration,
            threadPool: databases.threadPool
        )
        let pool = EventLoopGroupConnectionPool(
            source: db,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            on: databases.eventLoopGroup
        )
        return _FluentSQLiteDriver(pool: pool)
    }
}

extension SQLiteConfiguration {
    public static func file(_ path: String) -> Self {
        .init(storage: .file(path: path))
    }

    public static var memory: Self {
        .init(storage: .memory)
    }
}
