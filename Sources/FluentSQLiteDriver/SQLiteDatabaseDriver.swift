import FluentSQL
import AsyncKit

internal struct SQLiteDatabaseDriver: DatabaseDriver, SQLDatabase {
    let pool: EventLoopGroupConnectionPool<SQLiteConnectionSource>
    
    var eventLoopGroup: EventLoopGroup {
        return self.pool.eventLoopGroup
    }
    
    func execute(
        query: DatabaseQuery,
        database: Database,
        onRow: @escaping (DatabaseRow) -> ()
    ) -> EventLoopFuture<Void> {
        guard let sql = SQLQueryConverter(delegate: SQLiteConverterDelegate()).convert(query) else {
            return database.eventLoop.future()
        }

        let serialized: (sql: String, binds: [SQLiteData])
        do {
            serialized = try sqliteSerialize(sql)
        } catch {
            return database.eventLoop.makeFailedFuture(error)
        }
        database.logger.debug("\(serialized.sql) \(serialized.binds)")
        return self.pool.withConnection { connection in
            return connection.query(serialized.sql, serialized.binds) { row in
                onRow(row)
            }.flatMapThrowing { result in
                switch query.action {
                case .create:
                    let row = LastInsertRow(lastAutoincrementID: connection.lastAutoincrementID)
                    onRow(row)
                default: break
                }
            }
        }
    }
    
    func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) throws -> ()) -> EventLoopFuture<Void> {
        return self.pool.withConnection { connection in
            let serialized: (sql: String, binds: [SQLiteData])
            do {
                serialized = try sqliteSerialize(query)
            } catch {
                return connection.eventLoop.makeFailedFuture(error)
            }
            return connection.query(serialized.sql, serialized.binds) { row in
                try onRow(row)
            }
        }
    }
    
    func execute(
        schema: DatabaseSchema,
        database: Database
    ) -> EventLoopFuture<Void> {
        let sql = SQLSchemaConverter(delegate: SQLiteConverterDelegate()).convert(schema)
        let serialized: (sql: String, binds: [SQLiteData])
        do {
            serialized = try sqliteSerialize(sql)
        } catch {
            return database.eventLoop.makeFailedFuture(error)
        }
        database.logger.info("\(serialized.sql) \(serialized.binds)")
        return self.pool.withConnection {  connection in
            return connection.query(serialized.sql, serialized.binds) { row in
                fatalError("Unexpected output: \(row)")
            }
        }
    }
    
    func shutdown() {
        self.pool.shutdown()
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
