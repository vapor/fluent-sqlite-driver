public enum FluentSQLiteSchemaStatement: FluentSQLSchemaStatement {
    public static var createTable: FluentSQLiteSchemaStatement { return ._createTable }
    public static var alterTable: FluentSQLiteSchemaStatement { return ._alterTable }
    public static var dropTable: FluentSQLiteSchemaStatement { return ._dropTable }
    
    case _createTable
    case _alterTable
    case _dropTable
}

public struct FluentSQLiteSchema: FluentSQLSchema {
    public typealias Statement = FluentSQLiteSchemaStatement
    public typealias TableIdentifier = SQLiteTableIdentifier
    public typealias ColumnDefinition = SQLiteColumnDefinition
    public typealias TableConstraint = SQLiteTableConstraint

    public var statement: Statement
    public var table: TableIdentifier
    public var columns: [SQLiteColumnDefinition]
    public var deleteColumns: [SQLiteColumnIdentifier]
    public var constraints: [SQLiteTableConstraint]
    public var deleteConstraints: [SQLiteTableConstraint]
    
    public static func schema(_ statement: Statement, _ table: TableIdentifier) -> FluentSQLiteSchema {
        return .init(
            statement: statement,
            table: table,
            columns: [],
            deleteColumns: [],
            constraints: [],
            deleteConstraints: []
        )
    }
}
