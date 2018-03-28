import Async
import Fluent
import FluentSQL
import Foundation
import SQLite

extension SQLiteDatabase: SchemaSupporting {
    /// See SchemaExecutor.execute()
    public static func execute(schema: DatabaseSchema<SQLiteDatabase>, on connection: SQLiteConnection) -> Future<Void> {
        return Future.flatMap(on: connection) {
            guard schema.removeReferences.count <= 0 else {
                throw FluentSQLiteError(
                    identifier: "unsupported",
                    reason: "SQLite does not support deleting foreign keys",
                    source: .capture()
                )
            }

            var schemaQuery = schema.makeSchemaQuery(dataTypeFactory: dataType)
            schema.applyReferences(to: &schemaQuery)
            let string = SQLiteSQLSerializer()
                .serialize(schema: schemaQuery)

            return connection.query(string: string).run().flatMap(to: Void.self) {
                /// handle indexes as separate query
                var indexFutures: [Future<Void>] = []
                
                for addIndex in schema.addIndexes {
                    let fields = addIndex.fields.map { "`\($0.name)`" }.joined(separator: ", ")
                    let name = addIndex.sqliteName(for: schema.entity)
                    let add = connection.query(string: "CREATE \(addIndex.isUnique ? "UNIQUE " : "")INDEX `\(name)` ON `\(schema.entity)` (\(fields))").run()
                    indexFutures.append(add)
                }

                for removeIndex in schema.removeIndexes {
                    let name = removeIndex.sqliteName(for: schema.entity)
                    let remove = connection.query(string: "DROP INDEX `\(name)`").run()
                    indexFutures.append(remove)
                }

                return indexFutures.flatten(on: connection)
            }
        }
    }

    /// See SchemaSupporting.dataType
    public static func dataType(for field: SchemaField<SQLiteDatabase>) -> String {
        var sql: [String] = []
        switch field.type {
        case .blob: sql.append("BLOB")
        case .integer: sql.append("INTEGER")
        case .real: sql.append("REAL")
        case .text: sql.append("TEXT")
        case .null: sql.append("NULL")
        }

        if field.isIdentifier {
            sql.append("PRIMARY KEY")
        }

        if !field.isOptional {
            sql.append("NOT NULL")
        }

        return sql.joined(separator: " ")
    }

    /// See SchemaSupporting.fieldType
    public static func fieldType(for type: Any.Type) throws -> SQLiteFieldType {
        guard let convertible = type as? SQLiteFieldTypeStaticRepresentable.Type else {
            throw FluentSQLiteError(
                identifier: "fieldType",
                reason: "`\(type)` does not conform to `SQLiteFieldTypeStaticRepresentable`",
                source: .capture()
            )
        }
        return convertible.sqliteFieldType
    }
}

extension SchemaIndex {
    func sqliteName(for entity: String) -> String {
        return "_fluent_index_\(entity)_" + fields.map { $0.name }.joined(separator: "_")
    }
}
