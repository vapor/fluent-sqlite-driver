import Logging

extension DatabaseID {
    public static var sqlite: DatabaseID {
        return .init(string: "sqlite")
    }
}

extension Databases {
    public mutating func sqlite(
        configuration: SQLiteConfiguration = .init(storage: .memory),
        threadPool: NIOThreadPool,
        poolConfiguration: ConnectionPoolConfig = .init(),
        logger: Logger = .init(label: "codes.vapor.fluent.db.sqlite"),
        as id: DatabaseID = .sqlite,
        isDefault: Bool = true,
        eventLoop: EventLoop
    ) {
        let db = SQLiteConnectionSource(
            configuration: configuration,
            threadPool: threadPool,
            logger: logger,
            on: eventLoop
        )
        let pool = ConnectionPool(config: poolConfiguration, source: db)
        let driver = SQLiteDriver(pool: pool)
        self.add(driver, as: id, isDefault: isDefault)
    }
}

private final class SQLiteDriver: DatabaseDriver {
    var eventLoopGroup: EventLoopGroup {
        return self.pool.eventLoop
    }
    let pool: ConnectionPool<SQLiteConnectionSource>
    
    init(pool: ConnectionPool<SQLiteConnectionSource>) {
        self.pool = pool
    }
    
    func execute(_ query: DatabaseQuery, eventLoop: EventLoopPreference, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        return self.pool.withConnection { conn in
            return conn.execute(query, eventLoop: eventLoop, onOutput)
        }
    }
    
    func execute(_ schema: DatabaseSchema, eventLoop: EventLoopPreference) -> EventLoopFuture<Void> {
        return self.pool.withConnection { conn in
            return conn.execute(schema, eventLoop: eventLoop)
        }
    }
    
    func withConnection<T>(eventLoop: EventLoopPreference, _ closure: @escaping (DatabaseDriver) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return self.pool.withConnection(closure)
    }
    
    func shutdown() {
        try! self.pool.close().wait()
    }
    
}
