import NIOCore
import FluentKit
@preconcurrency import AsyncKit
import SQLiteNIO
import SQLiteKit
import Logging

struct FluentSQLiteDriver: DatabaseDriver {
    let pool: EventLoopGroupConnectionPool<SQLiteConnectionSource>
    let dataEncoder: SQLiteDataEncoder
    let dataDecoder: SQLiteDataDecoder
    let sqlLogLevel: Logger.Level?

    var eventLoopGroup: any EventLoopGroup {
        self.pool.eventLoopGroup
    }

    func makeDatabase(with context: DatabaseContext) -> any Database {
        FluentSQLiteDatabase(
            database: ConnectionPoolSQLiteDatabase(pool: self.pool.pool(for: context.eventLoop), logger: context.logger),
            context: context,
            dataEncoder: self.dataEncoder,
            dataDecoder: self.dataDecoder,
            queryLogLevel: self.sqlLogLevel,
            inTransaction: false
        )
    }

    func shutdown() {
        self.pool.shutdown()
    }
}

struct ConnectionPoolSQLiteDatabase: SQLiteDatabase {
    let pool: EventLoopConnectionPool<SQLiteConnectionSource>
    let logger: Logger

    var eventLoop: any EventLoop {
        self.pool.eventLoop
    }

    func lastAutoincrementID() -> EventLoopFuture<Int> {
        self.pool.withConnection(logger: self.logger) { $0.lastAutoincrementID() }
    }

    func withConnection<T>(_ closure: @escaping (SQLiteConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.pool.withConnection(logger: self.logger) { closure($0) }
    }

    func query(_ query: String, _ binds: [SQLiteData], logger: Logger, _ onRow: @escaping @Sendable (SQLiteRow) -> Void) -> EventLoopFuture<Void> {
        self.withConnection {
            $0.query(query, binds, logger: logger, onRow)
        }
    }
}
