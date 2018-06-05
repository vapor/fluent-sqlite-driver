/// Registers and boots SQLite services.
public final class FluentSQLiteProvider: Provider {
    /// Create a new SQLite provider.
    public init() { }

    /// See Provider.register
    public func register(_ services: inout Services) throws {
        try services.register(FluentProvider())
        services.register { container -> SQLiteDatabase in
            let storage = try container.make(SQLiteStorage.self)
            return try SQLiteDatabase(storage: storage)
        }
        services.register(KeyedCache.self) { container -> SQLiteCache in
            let pool = try container.connectionPool(to: .sqlite)
            return .init(pool: pool)
        }
    }

    /// See Provider.boot
    public func didBoot(_ container: Container) throws -> Future<Void> {
        return .done(on: container)
    }
}

public typealias SQLiteCache = DatabaseKeyedCache<ConfiguredDatabase<SQLiteDatabase>>
extension SQLiteDatabase: KeyedCacheSupporting { }
extension SQLiteDatabase: Service { }
