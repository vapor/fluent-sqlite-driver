extension DatabaseDriverFactory {
    public static func sqlite(
        file: String,
        maxConnectionsPerEventLoop: Int = 1
    ) -> DatabaseDriverFactory {
        .sqlite(
            configuration: .init(file: file),
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop
        )
    }
    
    public static func sqlite(
        configuration: SQLiteConfiguration = .init(storage: .memory),
        maxConnectionsPerEventLoop: Int = 1
    ) -> DatabaseDriverFactory {
        return DatabaseDriverFactory { databases in
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
}


struct _FluentSQLiteDriver: DatabaseDriver {
    let pool: EventLoopGroupConnectionPool<SQLiteConnectionSource>
    
    var eventLoopGroup: EventLoopGroup {
        self.pool.eventLoopGroup
    }
    
    func makeDatabase(with context: DatabaseContext) -> Database {
        _FluentSQLiteDatabase(
            pool: self.pool.pool(for: context.eventLoop),
            context: context
        )
    }
    
    func shutdown() {
        self.pool.shutdown()
    }
}
