import NIOKit
import FluentSQL

public final class SQLiteConnectionSource: ConnectionPoolSource {
    public var eventLoop: EventLoop
    private let storage: SQLiteConnection.Storage
    private let threadPool: NIOThreadPool

    public init(storage: SQLiteConnection.Storage, threadPool: NIOThreadPool, on eventLoop: EventLoop) {
        self.storage = storage
        self.threadPool = threadPool
        self.eventLoop = eventLoop
    }

    public func makeConnection() -> EventLoopFuture<SQLiteConnection> {
        return SQLiteConnection.open(storage: self.storage, threadPool: self.threadPool, on: self.eventLoop)
    }
}

extension SQLiteConnection: ConnectionPoolItem { }


extension ConnectionPool: Database where Source.Connection: Database {
    public func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        return self.withConnection { $0.execute(query, onOutput) }
    }

    public func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
        return self.withConnection { $0.execute(schema) }
    }

    public func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return self.withConnection { $0.transaction(closure) }
    }
}

extension SQLiteError: DatabaseError { }

private struct SQLiteConverterDelegate: SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> SQLExpression? {
        switch dataType {
        case .string: return SQLRaw("TEXT")
        case .datetime: return SQLRaw("REAL")
        case .int64: return SQLRaw("INTEGER")
        default: return nil
        }
    }

    func nestedFieldExpression(_ column: String, _ path: [String]) -> SQLExpression {
        return SQLRaw("JSON_EXTRACT(\(column), '$.\(path[0])')")
    }
}

private struct SQLiteDialect: SQLDialect {
    var identifierQuote: SQLExpression {
        return SQLRaw("'")
    }

    var literalStringQuote: SQLExpression {
        return SQLRaw("\"")
    }

    var autoIncrementClause: SQLExpression {
        return SQLRaw("AUTOINCREMENT")
    }

    mutating func nextBindPlaceholder() -> SQLExpression {
        return SQLRaw("?")
    }

    func literalBoolean(_ value: Bool) -> SQLExpression {
        switch value {
        case true: return SQLRaw("TRUE")
        case false: return SQLRaw("FALSE")
        }
    }
}

extension SQLiteRow: DatabaseOutput {
    public func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        return try self.decode(column: field, as: T.self)
    }
}

extension SQLiteRow: SQLRow {
    public func decode<D>(column: String, as type: D.Type) throws -> D where D : Decodable {
        guard let data = self.column(column) else {
            fatalError()
        }
        return try SQLiteDataDecoder().decode(D.self, from: data)
    }
}

extension SQLiteConnection: Database {
    public func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return closure(self)
    }

    public func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        let sql = SQLQueryConverter(delegate: SQLiteConverterDelegate()).convert(query)
        var serializer = SQLSerializer(dialect: SQLiteDialect())
        sql.serialize(to: &serializer)
        return self.query(serializer.sql, serializer.binds.map { encodable in
            return try! SQLiteDataEncoder().encode(encodable)
        }) { row in
            try! onOutput(row)
        }.map {
            switch query.action {
            case .create:
                let row = LastInsertRow(lastAutoincrementID: self.lastAutoincrementID)
                try! onOutput(row)
            default: break
            }
        }
    }

    public func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
        return self.sqlQuery(SQLSchemaConverter(delegate: SQLiteConverterDelegate()).convert(schema)) { row in
            fatalError("unexpected output")
        }
    }
}

extension SQLiteConnection: SQLDatabase {
    public func sqlQuery(_ query: SQLExpression, _ onRow: @escaping (SQLRow) throws -> ()) -> EventLoopFuture<Void> {
        var serializer = SQLSerializer(dialect: SQLiteDialect())
        query.serialize(to: &serializer)
        return self.query(serializer.sql, serializer.binds.map { encodable in
            return try! SQLiteDataEncoder().encode(encodable)
        }) { row in
            try! onRow(row)
        }
    }
}

private struct LastInsertRow: DatabaseOutput {
    var description: String {
        return ["id": lastAutoincrementID].description
    }

    let lastAutoincrementID: Int64?

    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        #warning("TODO: fixme, better logic")
        switch field {
        case "fluentID":
            if T.self is Int.Type {
                return Int(self.lastAutoincrementID!) as! T
            } else {
                fatalError()
            }
        default: throw ModelError.missingField(name: field)
        }
    }
}
