@_exported import Fluent
@_exported import SQLite


//extension SQLiteDatabase: QuerySupporting {
//    /// See `SQLDatabase`.
//    public typealias QueryJoin = SQLQuery.DML.Join
//
//    /// See `SQLDatabase`.
//    public typealias QueryJoinMethod = SQLQuery.DML.Join.Method
//
//    /// See `SQLDatabase`.
//    public typealias Query = SQLQuery.DML
//
//    /// See `SQLDatabase`.
//    public typealias Output = [SQLiteColumn: SQLiteData]
//
//    /// See `SQLDatabase`.
//    public typealias QueryAction = SQLQuery.DML.Statement
//
//    /// See `SQLDatabase`.
//    public typealias QueryAggregate = String
//
//    /// See `SQLDatabase`.
//    public typealias QueryData = [SQLQuery.DML.Column: SQLQuery.DML.Value]
//
//    /// See `SQLDatabase`.
//    public typealias QueryField = SQLQuery.DML.Column
//
//    /// See `SQLDatabase`.
//    public typealias QueryFilterMethod = SQLQuery.DML.Predicate.Comparison
//
//    /// See `SQLDatabase`.
//    public typealias QueryFilterValue = SQLQuery.DML.Value
//
//    /// See `SQLDatabase`.
//    public typealias QueryFilter = SQLQuery.DML.Predicate
//
//    /// See `SQLDatabase`.
//    public typealias QueryFilterRelation = SQLQuery.DML.Predicate.Relation
//
//    /// See `SQLDatabase`.
//    public typealias QueryKey = SQLQuery.DML.Key
//
//    /// See `SQLDatabase`.
//    public typealias QuerySort = SQLQuery.DML.OrderBy
//
//    /// See `SQLDatabase`.
//    public typealias QuerySortDirection = SQLQuery.DML.OrderBy.Direction
//
//    /// See `SQLDatabase`.
//    public static func queryExecute(_ dml: SQLQuery.DML, on conn: SQLiteConnection, into handler: @escaping ([SQLiteColumn: SQLiteData], SQLiteConnection) throws -> ()) -> Future<Void> {
//        // always cache the names first
//        return conn.query(.init(.dml(dml))) { row in
//            try handler(row, conn)
//        }
//    }
//
//    /// See `SQLDatabase`.
//    public static func queryDecode<D>(_ data: [SQLiteColumn: SQLiteData], entity: String, as decodable: D.Type, on conn: SQLiteConnection) -> Future<D>
//        where D: Decodable
//    {
//        do {
//            let decoded = try SQLiteRowDecoder().decode(D.self, from: data, table: entity)
//            return conn.future(decoded)
//        } catch {
//            return conn.future(error: error)
//        }
//    }
//
//    /// See `SQLDatabase`.
//    public static func schemaColumnType(for type: Any.Type, primaryKey: Bool) -> SQLQuery.DDL.ColumnDefinition.ColumnType {
//        var sqliteType: SQLiteFieldTypeStaticRepresentable.Type?
//
//        if let optionalType = type as? AnyOptionalType.Type {
//            sqliteType = optionalType.anyWrappedType as? SQLiteFieldTypeStaticRepresentable.Type
//        } else {
//            sqliteType = type as? SQLiteFieldTypeStaticRepresentable.Type
//        }
//
//        if let type = sqliteType {
//            var name: String
//            var attributes: [String] = []
//
//            switch type.sqliteFieldType {
//            case .blob: name = "BLOB"
//            case .integer: name = "INTEGER"
//            case .null: name = "NULL"
//            case .real: name = "REAL"
//            case .text: name = "TEXT"
//            }
//
//            if primaryKey {
//                attributes.append("PRIMARY KEY")
//            }
//
//            return .init(name: name, attributes: attributes)
//        } else {
//            fatalError("Unsupported SQLite type: \(type).")
//        }
//    }
//
//    /// See `SQLDatabase`.
//    public static func schemaExecute(_ ddl: SQLQuery.DDL, on conn: SQLiteConnection) -> EventLoopFuture<Void> {
//        // always cache the names first
//        return conn.query(.init(.ddl(ddl))).transform(to: ())
//    }
//
//    /// See `SQLSupporting`.
//    public static func enableForeignKeys(on conn: SQLiteConnection) -> Future<Void> {
//        return conn.query("PRAGMA foreign_keys = ON;").transform(to: ())
//    }
//
//    /// See `SQLSupporting`.
//    public static func disableForeignKeys(on conn: SQLiteConnection) -> Future<Void> {
//        return conn.query("PRAGMA foreign_keys = OFF;").transform(to: ())
//    }
//
//    /// See `SQLSupporting`.
//    public static func modelEvent<M>(event: ModelEvent, model: M, on conn: SQLiteConnection) -> Future<M> where SQLiteDatabase == M.Database, M: Model {
//        var copy = model
//        switch event {
//        case .willCreate:
//            if M.ID.self is UUID.Type {
//                copy.fluentID = UUID() as? M.ID
//            }
//        case .didCreate:
//            if M.ID.self is Int.Type {
//                copy.fluentID = conn.lastAutoincrementID as? M.ID
//            }
//        default: break
//        }
//        return conn.future(copy)
//    }
//
//    /// See `SQLSupporting`.
//    public static func transactionExecute<T>(_ transaction: @escaping (SQLiteConnection) throws -> Future<T>, on conn: SQLiteConnection) -> Future<T> {
//        return conn.query("BEGIN TRANSACTION").flatMap { _ -> Future<T> in
//            return try transaction(conn).flatMap { res -> Future<T> in
//                return conn.query("COMMIT TRANSACTION").transform(to: res)
//            }.catchFlatMap { err -> Future<T> in
//                return conn.query("ROLLBACK TRANSACTION").map { query -> T in
//                    // still fail even tho rollback succeeded
//                    throw err
//                }
//            }
//        }
//    }
//}
