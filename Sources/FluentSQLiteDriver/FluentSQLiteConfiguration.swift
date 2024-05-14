import NIO
import FluentKit
import SQLiteKit
import AsyncKit

extension DatabaseConfigurationFactory {
    public static func sqlite(
        _ configuration: SQLiteConfiguration = .init(storage: .memory),
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10),
        dataEncoder: SQLiteDataEncoder = .init(),
        dataDecoder: SQLiteDataDecoder = .init(),
        sqlLogLevel: Logger.Level = .debug
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
