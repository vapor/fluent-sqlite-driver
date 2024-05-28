import FluentSQL
import SQLiteKit
import NIOCore
import SQLiteNIO
import SQLKit
import FluentKit

struct FluentSQLiteDatabase: Database, SQLDatabase, SQLiteDatabase {
    let database: any SQLiteDatabase
    let context: DatabaseContext
    let dataEncoder: SQLiteDataEncoder
    let dataDecoder: SQLiteDataDecoder
    let queryLogLevel: Logger.Level?
    let inTransaction: Bool
    
    private func adjustFluentQuery(_ original: DatabaseQuery, _ converted: any SQLExpression) -> any SQLExpression {
        /// For `.create` query actions, we want to return the generated IDs, unless the `customIDKey` is the
        /// empty string, which we use as a very hacky signal for "we don't implement this for composite IDs yet".
        if case .create = original.action, original.customIDKey != .some(.string("")) {
            return SQLKit.SQLList([converted, SQLReturning(.init((original.customIDKey ?? .id).description))], separator: SQLRaw(" "))
        } else {
            return converted
        }
    }
    
    // Database
    
    func execute(query: DatabaseQuery, onOutput: @escaping @Sendable (any DatabaseOutput) -> ()) -> EventLoopFuture<Void> {
        /// SQLiteKit will handle applying the configured data decoder to each row when providing `SQLRow`s.
        return self.execute(
            sql: self.adjustFluentQuery(query, SQLQueryConverter(delegate: SQLiteConverterDelegate()).convert(query)),
            { onOutput($0.databaseOutput()) }
        )
    }
    
    func execute(query: DatabaseQuery, onOutput: @escaping @Sendable (any DatabaseOutput) -> ()) async throws {
        try await self.execute(
            sql: self.adjustFluentQuery(query, SQLQueryConverter(delegate: SQLiteConverterDelegate()).convert(query)),
            { onOutput($0.databaseOutput()) }
        )
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        var schema = schema
        
        if schema.action == .update {
            schema.updateFields = schema.updateFields.filter { switch $0 { // Filter out enum updates.
                case .dataType(_, .enum(_)): return false
                default: return true
            } }
            guard schema.createConstraints.isEmpty, schema.updateFields.isEmpty, schema.deleteConstraints.isEmpty else {
                return self.eventLoop.makeFailedFuture(FluentSQLiteUnsupportedAlter())
            }
            if schema.createFields.isEmpty, schema.deleteFields.isEmpty { // If there were only enum updates, bail out.
                return self.eventLoop.makeSucceededFuture(())
            }
        }
        
        return self.execute(
            sql: SQLSchemaConverter(delegate: SQLiteConverterDelegate()).convert(schema),
            { self.logger.debug("Unexpected row returned from schema query: \($0)") }
        )
    }

    func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(())
    }
    
    func withConnection<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.eventLoop.makeFutureWithTask { try await self.withConnection { try await closure($0).get() } }
    }
    
    func withConnection<T>(_ closure: @escaping @Sendable (any Database) async throws -> T) async throws -> T {
        try await self.withConnection {
            try await closure(FluentSQLiteDatabase(
                database: $0,
                context: self.context,
                dataEncoder: self.dataEncoder,
                dataDecoder: self.dataDecoder,
                queryLogLevel: self.queryLogLevel,
                inTransaction: self.inTransaction
            ))
        }
    }
    
    func transaction<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.inTransaction ?
            closure(self)  :
            self.eventLoop.makeFutureWithTask { try await self.transaction { try await closure($0).get() } }
    }
    
    func transaction<T>(_ closure: @escaping @Sendable (any Database) async throws -> T) async throws -> T {
        guard !self.inTransaction else {
            return try await closure(self)
        }

        return try await self.withConnection { conn in
            let db = FluentSQLiteDatabase(
                database: conn,
                context: self.context,
                dataEncoder: self.dataEncoder,
                dataDecoder: self.dataDecoder,
                queryLogLevel: self.queryLogLevel,
                inTransaction: true
            )
            
            try await db.raw("BEGIN TRANSACTION").run()
            do {
                let result = try await closure(db)
                
                try await db.raw("COMMIT TRANSACTION").run()
                return result
            } catch {
                try? await db.raw("ROLLBACK TRANSACTION").run()
                throw error
            }
        }
    }
    
    // SQLDatabase

    var dialect: any SQLDialect {
        self.database.sql(encoder: self.dataEncoder, decoder: self.dataDecoder, queryLogLevel: self.queryLogLevel).dialect
    }
    
    var version: (any SQLDatabaseReportedVersion)? {
        self.database.sql(encoder: self.dataEncoder, decoder: self.dataDecoder, queryLogLevel: self.queryLogLevel).version
    }
    
    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> ()) -> EventLoopFuture<Void> {
        self.database.sql(encoder: self.dataEncoder, decoder: self.dataDecoder, queryLogLevel: self.queryLogLevel).execute(sql: query, onRow)
    }
    
    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> ()) async throws {
        try await self.database.sql(encoder: self.dataEncoder, decoder: self.dataDecoder, queryLogLevel: self.queryLogLevel).execute(sql: query, onRow)
    }
    
    func withSession<R>(_ closure: @escaping @Sendable (any SQLDatabase) async throws -> R) async throws -> R {
        try await self.database.sql(encoder: self.dataEncoder, decoder: self.dataDecoder, queryLogLevel: self.queryLogLevel).withSession(closure)
    }

    // SQLiteDatabase
    
    func query(_ query: String, _ binds: [SQLiteData], logger: Logger, _ onRow: @escaping @Sendable (SQLiteRow) -> Void) -> EventLoopFuture<Void> {
        self.withConnection { $0.query(query, binds, logger: logger, onRow) }
    }

    func withConnection<T>(_ closure: @escaping @Sendable (SQLiteConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
}

private struct FluentSQLiteUnsupportedAlter: Error, CustomStringConvertible {
    var description: String {
        "SQLite only supports adding columns in ALTER TABLE statements."
    }
}
