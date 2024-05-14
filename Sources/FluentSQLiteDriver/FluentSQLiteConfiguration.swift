import NIO
import FluentKit
import SQLiteKit
import AsyncKit
import Logging

// Hint: Yes, I know what default arguments are. This ridiculous spelling out of each alternative avoids public API
// breakage from adding the defaults. And yes, `maxConnectionsPerEventLoop` is not forwarded on purpose, it's not
// an oversight or an omission. We no longer support it for SQLite because increasing it past one causes thread
// conntention but can never increase parallelism.

extension DatabaseConfigurationFactory {
    /// Shorthand for ``sqlite(_:maxConnectionsPerEventLoop:connectionPoolTimeout:dataEncoder:dataDecoder:sqlLogLevel:)``.
    public static func sqlite(_ config: SQLiteConfiguration = .memory, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10)) -> Self {
        self.sqlite(config, connectionPoolTimeout: connectionPoolTimeout, dataEncoder: .init(), dataDecoder: .init(), sqlLogLevel: .debug)
    }
    /// Shorthand for ``sqlite(_:maxConnectionsPerEventLoop:connectionPoolTimeout:dataEncoder:dataDecoder:sqlLogLevel:)``.
    public static func sqlite(
        _ config: SQLiteConfiguration = .memory, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10), dataEncoder: SQLiteDataEncoder
    ) -> Self {
        self.sqlite(config, connectionPoolTimeout: connectionPoolTimeout, dataEncoder: dataEncoder, dataDecoder: .init(), sqlLogLevel: .debug)
    }
    /// Shorthand for ``sqlite(_:maxConnectionsPerEventLoop:connectionPoolTimeout:dataEncoder:dataDecoder:sqlLogLevel:)``.
    public static func sqlite(
        _ config: SQLiteConfiguration = .memory, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10), dataDecoder: SQLiteDataDecoder
    ) -> Self {
        self.sqlite(config, connectionPoolTimeout: connectionPoolTimeout, dataEncoder: .init(), dataDecoder: dataDecoder, sqlLogLevel: .debug)
    }
    /// Shorthand for ``sqlite(_:maxConnectionsPerEventLoop:connectionPoolTimeout:dataEncoder:dataDecoder:sqlLogLevel:)``.
    public static func sqlite(
        _ config: SQLiteConfiguration = .memory, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10),
        dataEncoder: SQLiteDataEncoder, dataDecoder: SQLiteDataDecoder
    ) -> Self {
        self.sqlite(config, connectionPoolTimeout: connectionPoolTimeout, dataEncoder: dataEncoder, dataDecoder: dataDecoder, sqlLogLevel: .debug)
    }
    /// Shorthand for ``sqlite(_:maxConnectionsPerEventLoop:connectionPoolTimeout:dataEncoder:dataDecoder:sqlLogLevel:)``.
    public static func sqlite(
        _ config: SQLiteConfiguration = .memory, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10), sqlLogLevel: Logger.Level?
    ) -> Self {
        self.sqlite(config, connectionPoolTimeout: connectionPoolTimeout, dataEncoder: .init(), dataDecoder: .init(), sqlLogLevel: sqlLogLevel)
    }
    /// Shorthand for ``sqlite(_:maxConnectionsPerEventLoop:connectionPoolTimeout:dataEncoder:dataDecoder:sqlLogLevel:)``.
    public static func sqlite(
        _ config: SQLiteConfiguration = .memory, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10),
        dataEncoder: SQLiteDataEncoder, sqlLogLevel: Logger.Level?
    ) -> Self {
        self.sqlite(config, connectionPoolTimeout: connectionPoolTimeout, dataEncoder: dataEncoder, dataDecoder: .init(), sqlLogLevel: sqlLogLevel)
    }
    /// Shorthand for ``sqlite(_:maxConnectionsPerEventLoop:connectionPoolTimeout:dataEncoder:dataDecoder:sqlLogLevel:)``.
    public static func sqlite(
        _ config: SQLiteConfiguration = .memory, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10),
        dataDecoder: SQLiteDataDecoder, sqlLogLevel: Logger.Level?
    ) -> Self {
        self.sqlite(config, connectionPoolTimeout: connectionPoolTimeout, dataEncoder: .init(), dataDecoder: dataDecoder, sqlLogLevel: sqlLogLevel)
    }

    /// Return a configuration factory using the provided parameters.
    ///
    /// - Parameters:
    ///   - configuration: The underlying `SQLiteConfiguration`.
    ///   - maxConnnectionsPerEventLoop: Ignored. The value is always treated as 1.
    ///   - dataEncoder: An ``SQLiteDataEncoder`` used to translate bound query parameters into `SQLiteData` values.
    ///   - dataDecoder: An ``SQLiteDataDecoder`` used to translate `SQLiteData` values into output values.
    ///   - queryLogLevel: The level at which SQL queries issued through the Fluent or SQLKit interfaces will be logged.
    /// - Returns: A configuration factory,
    public static func sqlite(
        _ configuration: SQLiteConfiguration = .memory,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        dataEncoder: SQLiteDataEncoder,
        dataDecoder: SQLiteDataDecoder,
        sqlLogLevel: Logger.Level?
    ) -> Self {
        .init {
            FluentSQLiteConfiguration(
                configuration: configuration,
                middleware: [],
                connectionPoolTimeout: connectionPoolTimeout,
                dataEncoder: dataEncoder,
                dataDecoder: dataDecoder,
                sqlLogLevel: sqlLogLevel
            )
        }
    }
}

struct FluentSQLiteConfiguration: DatabaseConfiguration {
    let configuration: SQLiteConfiguration
    var middleware: [any AnyModelMiddleware]
    let connectionPoolTimeout: NIO.TimeAmount
    let dataEncoder: SQLiteDataEncoder
    let dataDecoder: SQLiteDataDecoder
    let sqlLogLevel: Logger.Level?

    func makeDriver(for databases: Databases) -> any DatabaseDriver {
        let db = SQLiteConnectionSource(
            configuration: self.configuration,
            threadPool: databases.threadPool
        )
        let pool = EventLoopGroupConnectionPool(
            source: db,
            maxConnectionsPerEventLoop: 1,
            requestTimeout: self.connectionPoolTimeout,
            on: databases.eventLoopGroup
        )
        return FluentSQLiteDriver(
            pool: pool,
            dataEncoder: self.dataEncoder,
            dataDecoder: self.dataDecoder,
            sqlLogLevel: self.sqlLogLevel
        )
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
