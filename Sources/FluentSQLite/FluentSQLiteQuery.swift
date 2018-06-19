public enum FluentSQLiteQueryStatement: FluentSQLQueryStatement {
    public static var insert: FluentSQLiteQueryStatement { return ._insert }
    public static var select: FluentSQLiteQueryStatement { return ._select }
    public static var update: FluentSQLiteQueryStatement { return ._update }
    public static var delete: FluentSQLiteQueryStatement { return ._delete }
    
    public var isInsert: Bool {
        switch self {
        case ._insert: return true
        default: return false
        }
    }
    
    case _insert
    case _select
    case _update
    case _delete
}

public struct FluentSQLiteQuery: FluentSQLQuery {
    public typealias Statement = FluentSQLiteQueryStatement
    public typealias TableIdentifier = SQLiteTableIdentifier
    public typealias Expression = SQLiteExpression
    public typealias SelectExpression = SQLiteSelectExpression
    public typealias Join = SQLiteJoin
    public typealias OrderBy = SQLiteOrderBy
    public typealias GroupBy = SQLiteGroupBy
    public typealias RowDecoder = SQLiteRowDecoder
    
    public var statement: Statement
    public var table: TableIdentifier
    public var keys: [SelectExpression]
    public var values: [String : Expression]
    public var joins: [Join]
    public var predicate: Expression?
    public var orderBy: [OrderBy]
    public var groupBy: [GroupBy]
    public var limit: Int?
    public var offset: Int?
    public var defaultBinaryOperator: GenericSQLBinaryOperator

    public static func query(_ statement: Statement, _ table: TableIdentifier) -> FluentSQLiteQuery {
        return .init(
            statement: statement,
            table: table,
            keys: [],
            values: [:],
            joins: [],
            predicate: nil,
            orderBy: [],
            groupBy: [],
            limit: nil,
            offset: nil,
            defaultBinaryOperator: .and
        )
    }
}
