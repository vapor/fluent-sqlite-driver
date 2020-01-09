extension DatabaseDriverFactory {
    public static func sqlite(
        file: String,
        threadPool: NIOThreadPool,
        maxConnectionPerEventLoop: Int = 1
    ) -> DatabaseDriverFactory {
        return self.sqlite(
            configuration: .init(file: file),
            threadPool: threadPool,
            maxConnectionPerEventLoop: maxConnectionPerEventLoop
        )
    }

    public static func sqlite(
        storage: SQLiteConfiguration.Storage,
        threadPool: NIOThreadPool,
        maxConnectionPerEventLoop: Int = 1
    ) -> DatabaseDriverFactory {
        return self.sqlite(
            configuration: .init(storage: storage),
            threadPool: threadPool,
            maxConnectionPerEventLoop: maxConnectionPerEventLoop
        )
    }

    public static func sqlite(
        configuration: SQLiteConfiguration,
        threadPool: NIOThreadPool,
        maxConnectionPerEventLoop: Int = 1
    ) -> DatabaseDriverFactory {
        return DatabaseDriverFactory { database in
            let source = SQLiteConnectionSource(configuration: configuration, threadPool: threadPool)
            let pool = EventLoopGroupConnectionPool(source: source, maxConnectionsPerEventLoop: maxConnectionPerEventLoop, on: database.eventLoopGroup)
            return _FluentSQliteDriver(pool: pool)
        }
    }
}


struct _FluentSQliteDriver: DatabaseDriver {
    let pool: EventLoopGroupConnectionPool<SQLiteConnectionSource>

    var eventLoopGroup: EventLoopGroup { self.pool.eventLoopGroup }

    func makeDatabase(with context: DatabaseContext) -> Database {
        _FluentSQLiteDatabase(
            database: self.pool.pool(for: context.eventLoop).database(logger: context.logger),
            context: context,
            encoder: .init(),
            decoder: .init()
        )
    }

    func shutdown() {
        self.pool.shutdown()
    }
}


extension EventLoopConnectionPool where Source == SQLiteConnectionSource {
    public func database(logger: Logger) -> SQLiteDatabase {
        _ConnectionPoolSQLiteDatabase(pool: self, logger: logger)
    }
}

private struct _ConnectionPoolSQLiteDatabase {
    let pool: EventLoopConnectionPool<SQLiteConnectionSource>
    let logger: Logger
}

extension _ConnectionPoolSQLiteDatabase: SQLiteDatabase {
    var eventLoop: EventLoop { self.pool.eventLoop }

    func query(_ query: String, _ binds: [SQLiteData], logger: Logger, _ onRow: @escaping (SQLiteRow) -> Void) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: logger) { connection in
            return connection.query(query, binds, logger: logger, onRow)
        }
    }

    func withConnection<T>(_ closure: @escaping (SQLiteConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.pool.withConnection(logger: self.logger, closure)
    }
}
