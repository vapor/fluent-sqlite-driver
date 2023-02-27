import NIOCore
import FluentKit
import AsyncKit
import SQLiteNIO
import SQLiteKit
import Logging

struct _FluentSQLiteDriver: DatabaseDriver {
    let pool: EventLoopGroupConnectionPool<SQLiteConnectionSource>

    var eventLoopGroup: EventLoopGroup {
        self.pool.eventLoopGroup
    }

    func makeDatabase(with context: DatabaseContext) -> Database {
        _FluentSQLiteDatabase(
            database: _ConnectionPoolSQLiteDatabase(pool: self.pool.pool(for: context.eventLoop), logger: context.logger),
            context: context,
            inTransaction: false
        )
    }

    func shutdown() {
        self.pool.shutdown()
    }
}

struct _ConnectionPoolSQLiteDatabase {
    let pool: EventLoopConnectionPool<SQLiteConnectionSource>
    let logger: Logger
}

extension _ConnectionPoolSQLiteDatabase: SQLiteDatabase {
    var eventLoop: EventLoop {
        self.pool.eventLoop
    }

    func lastAutoincrementID() -> EventLoopFuture<Int> {
        self.pool.withConnection(logger: self.logger) {
            $0.lastAutoincrementID()
        }
    }

    func withConnection<T>(_ closure: @escaping (SQLiteConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.pool.withConnection {
            closure($0)
        }
    }

    func query(_ query: String, _ binds: [SQLiteData], logger: Logger, _ onRow: @escaping (SQLiteRow) -> Void) -> EventLoopFuture<Void> {
        self.withConnection {
            $0.query(query, binds, logger: logger, onRow)
        }
    }
}
