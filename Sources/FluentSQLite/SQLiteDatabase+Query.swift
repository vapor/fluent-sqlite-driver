import Async
import Fluent
import FluentSQL
import Foundation
import SQLite
import SQL

extension SQLiteDatabase: QuerySupporting {
    /// See `QuerySupporting.QueryData`
    public typealias QueryData = SQLiteData

    /// See `QuerySupporting.QueryDataConvertible`
    public typealias QueryDataConvertible = SQLiteDataConvertible

    /// See `QuerySupporting.execute`
    public static func execute(
        query: DatabaseQuery<SQLiteDatabase>,
        into handler: @escaping ([QueryField : SQLiteData], SQLiteConnection) throws -> (),
        on connection: SQLiteConnection
    ) -> EventLoopFuture<Void> {
        return Future.flatMap(on: connection) {
            /// convert fluent query to sql query
            var (dataQuery, binds) = query.makeDataQuery()

            // bind model columns to sql query
            query.data.forEach { key, val in
                let col = DataColumn(table: query.entity, name: key.name)
                dataQuery.columns.append(col)
            }

            /// create sqlite query from string
            let sqlString = SQLiteSQLSerializer().serialize(data: dataQuery)
            let sqliteQuery = connection.query(string: sqlString)

            /// bind model data to sqlite query
            for data in query.data.values {
                sqliteQuery.bind(data)
            }

            /// encode sql placeholder binds
            for bind in binds {
                sqliteQuery.bind(bind)
            }

            return sqliteQuery.run { row, query in
                var res: [QueryField: SQLiteData] = [:]
                for (col, data) in row.fields {
                    let field = QueryField(entity: col.table, name: col.name)
                    res[field] = data.data
                }

                try handler(res, connection)
            }
        }
    }

    /// See `QuerySupporting.modelEvent`
    public static func modelEvent<M>(
        event: ModelEvent,
        model: M,
        on connection: SQLiteConnection
    ) -> Future<M> where SQLiteDatabase == M.Database, M: Model {
        var copy = model
        switch event {
        case .willCreate:
            switch id(M.ID.self) {
            case id(UUID.self): copy.fluentID = UUID() as? M.ID
            default: break
            }
        case .didCreate:
            switch id(M.ID.self) {
            case id(Int.self): copy.fluentID = connection.lastAutoincrementID as? M.ID
            default: break
            }
        default: break
        }

        return Future.map(on: connection) { copy }
    }

    /// See `QuerySupporting.queryDataParse`
    public static func queryDataParse<T>(_ type: T.Type, from data: SQLiteData) throws -> T? {
        if data.isNull { return nil }
        guard let convertibleType = T.self as? SQLiteDataConvertible.Type else {
            throw FluentSQLiteError(identifier: "queryDataParse", reason: "Cannot parse \(T.self) from SQLiteData", source: .capture())
        }
        let t: T = try convertibleType.convertFromSQLiteData(data) as! T
        return t
    }

    /// See `QuerySupporting.queryDataSerialize`
    public static func queryDataSerialize<T>(data: T?) throws -> SQLiteData {
        if let data = data {
            guard let convertible = data as? SQLiteDataConvertible else {
                throw FluentSQLiteError(identifier: "queryDataSerialize", reason: "Cannot serialize \(T.self) to SQLiteData", source: .capture())
            }
            return try convertible.convertToSQLiteData()
        } else {
            return .null
        }
    }

    /// See `QuerySupporting.QueryFilter`
    public typealias QueryFilter = DataPredicateComparison
}

extension SQLiteData: FluentData { }
