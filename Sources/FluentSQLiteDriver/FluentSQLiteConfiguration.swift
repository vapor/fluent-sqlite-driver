import NIO
import FluentKit
import SQLiteKit
import AsyncKit

extension DatabaseConfigurationFactory {
    public static func sqlite(
        _ configuration: SQLiteConfiguration = .init(storage: .memory),
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10)
    ) -> Self {
        return .init {
            FluentSQLiteConfiguration(
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                middleware: [],
                connectionPoolTimeout: connectionPoolTimeout
            )
        }
    }
}

struct FluentSQLiteConfiguration: DatabaseConfiguration {
    let configuration: SQLiteConfiguration
    let maxConnectionsPerEventLoop: Int
    var middleware: [AnyModelMiddleware]
    let connectionPoolTimeout: NIO.TimeAmount

    func makeDriver(for databases: Databases) -> DatabaseDriver {
        let db = SQLiteConnectionSource(
            configuration: configuration,
            threadPool: databases.threadPool
        )
        let pool = EventLoopGroupConnectionPool(
            source: db,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            requestTimeout: connectionPoolTimeout,
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
