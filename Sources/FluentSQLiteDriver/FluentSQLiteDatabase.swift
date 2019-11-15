import FluentSQL

struct _FluentSQLiteDatabase {
    let database: SQLiteDatabase
    let context: DatabaseContext
}

extension _FluentSQLiteDatabase: Database {
    func execute(query: DatabaseQuery, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        let sql = SQLQueryConverter(delegate: SQLiteConverterDelegate()).convert(query)
        let serialized: (sql: String, binds: [SQLiteData])
        do {
            serialized = try sqliteSerialize(sql)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.database.withConnection { connection in
            connection.logging(to: self.logger)
                .query(serialized.sql, serialized.binds, onRow)
                .flatMap {
                    switch query.action {
                    case .create:
                        return connection.lastAutoincrementID().map {
                            onRow(LastInsertRow(lastAutoincrementID: $0))
                        }
                    default:
                        return self.eventLoop.makeSucceededFuture(())
                    }
                }
        }
    }
    
    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let sql = SQLSchemaConverter(delegate: SQLiteConverterDelegate()).convert(schema)
        let serialized: (sql: String, binds: [SQLiteData])
        do {
            serialized = try sqliteSerialize(sql)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.database.logging(to: self.logger).query(serialized.sql, serialized.binds) {
            fatalError("Unexpected output: \($0)")
        }
    }
    
    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection {
            closure(_FluentSQLiteDatabase(database: $0, context: self.context))
        }
    }
}

extension _FluentSQLiteDatabase: SQLDatabase {
    func execute(
        sql query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) -> EventLoopFuture<Void> {
        self.logging(to: self.logger).sql().execute(sql: query, onRow)
    }
}

extension _FluentSQLiteDatabase: SQLiteDatabase {
    func withConnection<T>(_ closure: @escaping (SQLiteConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
    
    func query(
        _ query: String,
        _ binds: [SQLiteData],
        logger: Logger,
        _ onRow: @escaping (SQLiteRow) -> Void
    ) -> EventLoopFuture<Void> {
        self.database.query(query, binds, logger: logger, onRow)
    }
}

private func sqliteSerialize(_ sql: SQLExpression) throws -> (String, [SQLiteData]) {
    var serializer = SQLSerializer(dialect: SQLiteDialect())
    sql.serialize(to: &serializer)
    let binds: [SQLiteData]
    binds = try serializer.binds.map { encodable in
        return try SQLiteDataEncoder().encode(encodable)
    }
    return (serializer.sql, binds)
}

private struct LastInsertRow: DatabaseRow {
    var description: String {
        return ["id": lastAutoincrementID].description
    }

    let lastAutoincrementID: Int

    init(lastAutoincrementID: Int) {
        self.lastAutoincrementID = lastAutoincrementID
    }

    func contains(field: String) -> Bool {
        return field == "fluentID"
    }

    func decode<T>(field: String, as type: T.Type, for database: Database) throws -> T where T : Decodable {
        switch field {
        case "fluentID":
            if T.self is Int?.Type || T.self is Int.Type {
                return self.lastAutoincrementID as! T
            } else {
                fatalError("cannot decode last autoincrement type: \(T.self)")
            }
        default:
            throw FluentError.missingField(name: field)
        }
    }
}
