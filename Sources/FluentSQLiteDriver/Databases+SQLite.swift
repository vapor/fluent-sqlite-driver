import Logging

extension DatabaseID {
    public static var sqlite: DatabaseID {
        return .init(string: "sqlite")
    }
}

extension Databases {
    public func sqlite(
        configuration: SQLiteConfiguration = .init(storage: .memory),
        threadPool: NIOThreadPool,
        poolConfiguration: ConnectionPoolConfiguration = .init(),
        logger: Logger = .init(label: "codes.vapor.sqlite"),
        as id: DatabaseID = .sqlite,
        isDefault: Bool = true,
        on eventLoopGroup: EventLoopGroup
    ) {
        let db = SQLiteConnectionSource(
            configuration: configuration,
            threadPool: threadPool,
            logger: logger
        )
        let pool = ConnectionPool(configuration: poolConfiguration, source: db, on: eventLoopGroup)
        self.add(SQLiteDatabaseDriver(pool: pool), logger: logger, as: id, isDefault: isDefault)
    }
}
