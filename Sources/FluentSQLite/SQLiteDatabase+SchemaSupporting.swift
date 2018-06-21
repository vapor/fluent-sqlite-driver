extension SQLiteDatabase: SQLConstraintIdentifierNormalizer {
    /// See `SQLConstraintIdentifierNormalizer`.
    public static func normalizeSQLConstraintIdentifier(_ identifier: String) -> String {
        return identifier
    }
}

extension SQLiteDatabase: SchemaSupporting {
    /// See `SchemaSupporting`.
    public typealias Schema = FluentSQLiteSchema
    
    /// See `SchemaSupporting`.
    public typealias SchemaAction = FluentSQLiteSchemaStatement
    
    /// See `SchemaSupporting`.
    public typealias SchemaField = SQLiteColumnDefinition
    
    /// See `SchemaSupporting`.
    public typealias SchemaFieldType = SQLiteDataType
    
    /// See `SchemaSupporting`.
    public typealias SchemaConstraint = SQLiteTableConstraint
    
    /// See `SchemaSupporting`.
    public typealias SchemaReferenceAction = SQLiteForeignKeyAction
    
    /// See `SchemaSupporting`.
    public static func schemaField(for type: Any.Type, isIdentifier: Bool, _ field: QueryField) -> SchemaField {
        var type = type
        var constraints: [SQLiteColumnConstraint] = []
        
        if let optional = type as? AnyOptionalType.Type {
            type = optional.anyWrappedType
        } else {
            constraints.append(.notNull)
        }
        
        let typeName: SQLiteDataType
        if let sqlite = type as? SQLiteDataTypeStaticRepresentable.Type {
            switch sqlite.sqliteDataType {
            case .blob: typeName = .blob
            case .integer: typeName = .integer
            case .null: typeName = .null
            case .real: typeName = .real
            case .text: typeName = .text
            }
        } else {
            typeName = .text
        }
        
        if isIdentifier {
            constraints.append(.notNull)
            // SQLite should not use AUTOINCREMENT for INTEGER PRIMARY KEY since it is an alias for ROWID
            constraints.append(.primaryKey(default: nil))
        }
        
        return .columnDefinition(field, typeName, constraints)
    }
    
    /// See `SchemaSupporting`.
    public static func schemaExecute(_ fluent: Schema, on conn: SQLiteConnection) -> Future<Void> {
        let query: SQLiteQuery
        switch fluent.statement {
        case ._createTable:
            var createTable: SQLiteCreateTable = .createTable(fluent.table)
            createTable.columns = fluent.columns
            createTable.tableConstraints = fluent.constraints
            query = ._createTable(createTable)
        case ._alterTable:
            guard fluent.columns.count == 1 && fluent.constraints.count == 0 else {
                /// See https://www.sqlite.org/lang_altertable.html
                fatalError("SQLite only supports adding one (1) column in an ALTER query.")
            }
            query = .alterTable(.init(
                table: fluent.table,
                value: .addColumn(fluent.columns[0])
            ))
        case ._dropTable:
            let dropTable: SQLiteDropTable = .dropTable(fluent.table)
            query = ._dropTable(dropTable)
        }
        return conn.query(query).transform(to: ())
    }
    
    /// See `SchemaSupporting`.
    public static func enableReferences(on conn: SQLiteConnection) -> Future<Void> {
        return conn.query("PRAGMA foreign_keys = ON;").transform(to: ())
    }
    
    /// See `SchemaSupporting`.
    public static func disableReferences(on conn: SQLiteConnection) -> Future<Void> {
        return conn.query("PRAGMA foreign_keys = OFF;").transform(to: ())
    }
}
