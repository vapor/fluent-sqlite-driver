import FluentSQL

struct _FluentSQLiteDatabase {
    let pool: EventLoopConnectionPool<SQLiteConnectionSource>
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
        return self.pool.withConnection(logger: self.logger) { connection in
            connection.logging(to: self.logger)
                .query(serialized.sql, serialized.binds, onRow)
                .flatMapThrowing { _ in
                    switch query.action {
                    case .create:
                        let row = LastInsertRow(
                            lastAutoincrementID: connection.lastAutoincrementID
                        )
                        onRow(row)
                    default: break
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
        return self.pool.withConnection(logger: self.logger) {
            $0.logging(to: self.logger).query(serialized.sql, serialized.binds) {
                fatalError("Unexpected output: \($0)")
            }
        }
    }
}

extension _FluentSQLiteDatabase: SQLDatabase {
    func execute(
        sql query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: self.logger) {
            $0.logging(to: self.logger)
                .sql()
                .execute(sql: query, onRow)
        }
    }
}

extension _FluentSQLiteDatabase: SQLiteDatabase {
    func query(
        _ query: String,
        _ binds: [SQLiteData],
        logger: Logger,
        _ onRow: @escaping (SQLiteRow) -> Void
    ) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: self.logger) { connection in
            connection.query(query, binds, logger: logger, onRow)
        }
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

    let lastAutoincrementID: Int64?

    init(lastAutoincrementID: Int64?) {
        self.lastAutoincrementID = lastAutoincrementID
    }

    func contains(field: String) -> Bool {
        return field == "fluentID"
    }

    func decode<T>(field: String, as type: T.Type, for database: Database) throws -> T where T : Decodable {
        switch field {
        case "fluentID":
            if T.self is Int?.Type || T.self is Int.Type {
                return Int(self.lastAutoincrementID!) as! T
            } else {
                fatalError("cannot decode last autoincrement type: \(T.self)")
            }
        default:
            throw FluentError.missingField(name: field)
        }
    }
}
