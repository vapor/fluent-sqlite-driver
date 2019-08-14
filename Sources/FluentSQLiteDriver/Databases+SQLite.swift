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
        isDefault: Bool = true
    ) {
        let db = SQLiteConnectionSource(
            configuration: configuration,
            threadPool: threadPool,
            logger: logger,
            on: self.eventLoop
        )
        let pool = ConnectionPool(config: poolConfiguration, source: db)
        self.add(pool, as: id, isDefault: isDefault)
    }
}
