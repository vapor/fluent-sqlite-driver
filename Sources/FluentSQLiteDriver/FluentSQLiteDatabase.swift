import FluentSQL

struct _FluentSQLiteDatabase {
    let database: SQLiteDatabase
    let context: DatabaseContext

    let encoder: SQLiteDataEncoder
    let decoder: SQLiteDataDecoder
}

extension _FluentSQLiteDatabase: Database {
    func execute(query: DatabaseQuery, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        guard let expression = SQLQueryConverter(delegate: SQLiteConverterDelegate()).convert(query) else {
            return self.eventLoop.future()
        }
        let (sql, binds) = self.serialize(expression)

        do {
            return try self.query(sql, binds.map(self.encoder.encode), logger: self.context.logger, onRow)
        } catch let error {
            return self.eventLoop.future(error: error)
        }
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let expression = SQLSchemaConverter(delegate: SQLiteConverterDelegate()).convert(schema)
        let (sql, binds) = self.serialize(expression)

        do {
            return try self.query(sql, binds.map(self.encoder.encode), logger: self.context.logger) { row in
                fatalError("unexpected row: \(row)")
            }
        } catch let error {
            return self.eventLoop.future(error: error)
        }
    }

    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return self.database.withConnection { connection in
            closure(_FluentSQLiteDatabase(database: connection, context: self.context, encoder: self.encoder, decoder: self.decoder))
        }
    }
}

extension _FluentSQLiteDatabase: SQLDatabase {
    var dialect: SQLDialect { SQLiteDialect() }

    func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) -> ()) -> EventLoopFuture<Void> {
        self.sql().execute(sql: query, onRow)
    }
}

extension _FluentSQLiteDatabase: SQLiteDatabase {
    func query(_ query: String, _ binds: [SQLiteData], logger: Logger, _ onRow: @escaping (SQLiteRow) -> Void) -> EventLoopFuture<Void> {
        self.database.query(query, binds, logger: logger, onRow)
    }

    func withConnection<T>(_ closure: @escaping (SQLiteConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
}
