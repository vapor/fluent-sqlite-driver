extension SQLiteQuery {
    public struct FluentSchema {
        public enum Statement {
            case create
            case alter
            case drop
        }
        
        public var statement: Statement
        public var table: TableName
        public var columns: [SQLiteQuery.ColumnDefinition]
        public var constraints: [SQLiteQuery.TableConstraint]
        public init(_ statement: Statement, table: TableName) {
            self.statement = statement
            self.table = table
            self.columns = []
            self.constraints = []
        }
    }
}

extension SQLiteDatabase: SchemaSupporting {
    /// See `SchemaSupporting`.
    public typealias Schema = SQLiteQuery.FluentSchema
    
    /// See `SchemaSupporting`.
    public typealias SchemaAction = SQLiteQuery.FluentSchema.Statement
    
    /// See `SchemaSupporting`.
    public typealias SchemaField = SQLiteQuery.ColumnDefinition
    
    /// See `SchemaSupporting`.
    public typealias SchemaFieldType = SQLiteQuery.TypeName
    
    /// See `SchemaSupporting`.
    public typealias SchemaConstraint = SQLiteQuery.TableConstraint
    
    /// See `SchemaSupporting`.
    public typealias SchemaReferenceAction = SQLiteQuery.ForeignKeyReference.Action
    
    /// See `SchemaSupporting`.
    public static var schemaActionCreate: SQLiteQuery.FluentSchema.Statement {
        return .create
    }
    
    /// See `SchemaSupporting`.
    public static var schemaActionUpdate: SQLiteQuery.FluentSchema.Statement {
        return .alter
    }
    
    /// See `SchemaSupporting`.
    public static var schemaActionDelete: SQLiteQuery.FluentSchema.Statement {
        return .drop
    }
    
    /// See `SchemaSupporting`.
    public static func schemaCreate(_ action: SQLiteQuery.FluentSchema.Statement, _ entity: String) -> SQLiteQuery.FluentSchema {
        return .init(action, table: .init(name: entity))
    }
    
    /// See `SchemaSupporting`.
    public static func schemaField(for type: Any.Type, isIdentifier: Bool, _ field: SQLiteQuery.QualifiedColumnName) -> SQLiteQuery.ColumnDefinition {
        var type = type
        var constraints: [SQLiteQuery.ColumnConstraint] = []
        
        if let optional = type as? AnyOptionalType.Type {
            type = optional.anyWrappedType
        } else {
            constraints.append(.notNull)
        }
        
        let typeName: SQLiteQuery.TypeName
        if let sqlite = type as? SQLiteFieldTypeStaticRepresentable.Type {
            switch sqlite.sqliteFieldType {
            case .blob: typeName = .none
            case .integer: typeName = .integer
            case .null: typeName = .none
            case .real: typeName = .real
            case .text: typeName = .text
            }
        } else {
            typeName = .text
        }
        
        if isIdentifier {
            constraints.append(.notNull)
            switch typeName {
            case .integer: constraints.append(.primaryKey(autoIncrement: true))
            default: constraints.append(.primaryKey(autoIncrement: false))
            }
        }
        
        return .init(name: field.name, typeName: typeName, constraints: constraints)
    }
    
    /// See `SchemaSupporting`.
    public static func schemaField(_ field: SQLiteQuery.QualifiedColumnName, _ type: SQLiteQuery.TypeName) -> SQLiteQuery.ColumnDefinition {
        return .init(name: field.name, typeName: type, constraints: [])
    }
    
    /// See `SchemaSupporting`.
    public static func schemaFieldCreate(_ field: SQLiteQuery.ColumnDefinition, to query: inout SQLiteQuery.FluentSchema) {
        query.columns.append(field)
    }
    
    /// See `SchemaSupporting`.
    public static func schemaFieldDelete(_ field: SQLiteQuery.QualifiedColumnName, to query: inout SQLiteQuery.FluentSchema) {
        fatalError("SQLite does not support deleting columns from tables.")
    }
    
    /// See `SchemaSupporting`.
    public static func schemaReference(from: SQLiteQuery.QualifiedColumnName, to: SQLiteQuery.QualifiedColumnName, onUpdate: SQLiteQuery.ForeignKeyReference.Action?, onDelete: SQLiteQuery.ForeignKeyReference.Action?) -> SQLiteQuery.TableConstraint {
        return .init(
            name: "fk",
            value: .foreignKey(.init(
                columns: [from.name],
                reference: .init(
                    foreignTable: .init(name: to.table!),
                    foreignColumns: [to.name],
                    onDelete: onDelete,
                    onUpdate: onUpdate,
                    match: nil,
                    deferrence: nil
                )
            ))
        )
    }
    
    /// See `SchemaSupporting`.
    public static func schemaUnique(on: [SQLiteQuery.QualifiedColumnName]) -> SQLiteQuery.TableConstraint {
        return .init(
            name: "uq",
            value: .unique(.init(
                columns: on.map { .init(value: .column($0.name)) },
                conflictResolution: nil
            ))
        )
    }
    
    /// See `SchemaSupporting`.
    public static func schemaConstraintCreate(_ constraint: SQLiteQuery.TableConstraint, to query: inout SQLiteQuery.FluentSchema) {
        query.constraints.append(constraint)
    }
    
    /// See `SchemaSupporting`.
    public static func schemaConstraintDelete(_ constraint: SQLiteQuery.TableConstraint, to query: inout SQLiteQuery.FluentSchema) {
        fatalError("SQLite does not support deleting constraints from tables.")
    }
    
    /// See `SchemaSupporting`.
    public static func schemaExecute(_ fluent: SQLiteQuery.FluentSchema, on conn: SQLiteConnection) -> Future<Void> {
        let query: SQLiteQuery
        switch fluent.statement {
        case .create:
            query = .createTable(.init(
                temporary: false,
                ifNotExists: false,
                table: fluent.table,
                source: .schema(.init(
                    columns: fluent.columns,
                    tableConstraints: fluent.constraints,
                    withoutRowID: false
                ))
            ))
        case .alter:
            guard fluent.columns.count == 1 && fluent.constraints.count == 0 else {
                /// See https://www.sqlite.org/lang_altertable.html
                fatalError("SQLite only supports adding one (1) column in an ALTER query.")
            }
            query = .alterTable(.init(
                table: fluent.table,
                value: .addColumn(fluent.columns[0])
            ))
        case .drop:
            query = .dropTable(.init(
                table: fluent.table,
                ifExists: false
            ))
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
