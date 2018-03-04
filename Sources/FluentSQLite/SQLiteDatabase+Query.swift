import Async
import Fluent
import FluentSQL
import Foundation
import SQLite
import SQL

extension SQLiteDatabase: QuerySupporting {
    /// See QuerySupporting.execute
    public static func execute<D>(
        query: DatabaseQuery<SQLiteDatabase>,
        into handler: @escaping (D, SQLiteConnection) throws -> (),
        on connection: SQLiteConnection
    ) -> EventLoopFuture<Void> where D: Decodable {
        return Future.flatMap(on: connection) {
            /// convert fluent query to sql query
            var (dataQuery, binds) = query.makeDataQuery()

            // create row encoder, will only
            // be used if a model is being binded
            let rowEncoder = SQLiteRowEncoder()

            // bind model columns to sql query
            if let model = query.data {
                try model.encode(to: rowEncoder)
                rowEncoder.row.fields.forEach { key, val in
                    let col = DataColumn(table: query.entity, name: key.name)
                    dataQuery.columns.append(col)
                }
            }

            /// create sqlite query from string
            let sqlString = SQLiteSQLSerializer().serialize(data: dataQuery)
            let sqliteQuery = connection.query(string: sqlString)

            /// bind model data to sqlite query
            if query.data != nil {
                for data in rowEncoder.row.fields.values.map({ $0.data }) {
                    sqliteQuery.bind(data)
                }
            }

            /// encode sql placeholder binds
            let DataEncoder = SQLiteDataEncoder()
            for bind in binds {
                try sqliteQuery.bind(DataEncoder.makeSQLiteData(bind))
            }

            return sqliteQuery.run { row, query in
                let decoder = SQLiteRowDecoder(row: row)
                let model = try D(from: decoder)
                try handler(model, connection)
            }
        }
    }

    /// See QuerySupporting.modelEvent
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
}

extension SQLiteDataEncoder {
    /// Converts a SQL bind value into SQLite data.
    /// This method applies wildcards if necessary.
    fileprivate func makeSQLiteData(_ bind: BindValue) throws -> SQLiteData {
        try bind.encodable.encode(to: self)
        switch bind.method {
        case .plain:
            return data
        case .wildcard(let wildcard):
            // FIXME: fuzzy string
            guard let string = data.text else {
                throw FluentSQLiteError(identifier: "wildcard", reason: "Could not convert value with wildcards to string: \(data).", source: .capture())
            }

            switch wildcard {
            case .fullWildcard: return .text("%" + string + "%")
            case .leadingWildcard: return .text("%" + string)
            case .trailingWildcard: return .text(string + "%")
            }
        }
    }
}

