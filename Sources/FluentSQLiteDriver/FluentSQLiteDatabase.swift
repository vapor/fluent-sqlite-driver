import FluentSQL

struct _FluentSQLiteDatabase {
    let database: SQLiteDatabase
    let context: DatabaseContext
}

extension _FluentSQLiteDatabase: Database {
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {
        let sql = SQLQueryConverter(delegate: SQLiteConverterDelegate()).convert(query)
        let (string, binds) = self.serialize(sql)
        let data: [SQLiteData]
        do {
            data = try binds.map { encodable in
                try SQLiteDataEncoder().encode(encodable)
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.database.withConnection { connection in
            connection.logging(to: self.logger)
                .query(string, data) { row in
                    onOutput(row)
                }
                .flatMap {
                    switch query.action {
                    case .create:
                        return connection.lastAutoincrementID().map {
                            let row = LastInsertRow(
                                lastAutoincrementID: $0,
                                customIDKey: query.customIDKey
                            )
                            onOutput(row)
                        }
                    default:
                        return self.eventLoop.makeSucceededFuture(())
                    }
                }
        }
    }

    func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection { conn in
            conn.query("BEGIN TRANSACTION").flatMap { _ in
                let db = _FluentSQLiteDatabase(database: conn, context: self.context)
                return closure(db).flatMap { result in
                    conn.query("COMMIT TRANSACTION").map { _ in
                        result
                    }
                }.flatMapError { error in
                    conn.query("ROLLBACK TRANSACTION").flatMapThrowing { _ in
                        throw error
                    }
                }
            }
        }
    }
    
    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        switch schema.action {
        case .update:
            if schema.createFields.isEmpty {
                return self.eventLoop.makeSucceededFuture(())
            }
        default:
            break
        }
        let sql = SQLSchemaConverter(delegate: SQLiteConverterDelegate()).convert(schema)
        let (string, binds) = self.serialize(sql)
        let data: [SQLiteData]
        do {
            data = try binds.map { encodable in
                try SQLiteDataEncoder().encode(encodable)
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.database.logging(to: self.logger).query(string, data) {
            fatalError("Unexpected output: \($0)")
        }
    }

    func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        return self.eventLoop.makeSucceededFuture(())
    }
    
    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection {
            closure(_FluentSQLiteDatabase(database: $0, context: self.context))
        }
    }
}

extension _FluentSQLiteDatabase: SQLDatabase {
    var dialect: SQLDialect {
        SQLiteDialect()
    }
    
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

private struct LastInsertRow: DatabaseOutput {
    var description: String {
        ["id": self.lastAutoincrementID].description
    }

    let lastAutoincrementID: Int
    let customIDKey: FieldKey?

    func schema(_ schema: String) -> DatabaseOutput {
        return self
    }

    func contains(_ path: [FieldKey]) -> Bool {
        path[0] == .id || path[0] == self.customIDKey
    }

    func decode<T>(_ path: [FieldKey], as type: T.Type) throws -> T where T : Decodable {
        guard path[0] == .id || path[0] == self.customIDKey else {
            fatalError("Cannot decode field from last insert row: \(path).")
        }
        if let autoincrementInitializable = T.self as? AutoincrementIDInitializable.Type {
            return autoincrementInitializable.init(autoincrementID: self.lastAutoincrementID) as! T
        } else {
            fatalError("Unsupported database generated identiifer type: \(T.self)")
        }
    }
}

protocol AutoincrementIDInitializable {
    init(autoincrementID: Int)
}

extension AutoincrementIDInitializable where Self: FixedWidthInteger {
    init(autoincrementID: Int) {
        self = numericCast(autoincrementID)
    }
}

extension Int: AutoincrementIDInitializable { }
extension UInt: AutoincrementIDInitializable { }
extension Int64: AutoincrementIDInitializable { }
extension UInt64: AutoincrementIDInitializable { }
