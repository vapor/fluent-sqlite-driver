extension SQLiteDatabase: JoinSupporting {
    /// See `JoinSupporting`.
    public typealias QueryJoin = SQLiteQuery.JoinClause.Join
    
    /// See `JoinSupporting`.
    public typealias QueryJoinMethod = SQLiteQuery.JoinClause.Join.Operator
    
    /// See `JoinSupporting`.
    public static var queryJoinMethodDefault: SQLiteQuery.JoinClause.Join.Operator {
        return .inner
    }
    
    /// See `JoinSupporting`.
    public static func queryJoin(_ method: SQLiteQuery.JoinClause.Join.Operator, base: SQLiteQuery.QualifiedColumnName, joined: SQLiteQuery.QualifiedColumnName) -> SQLiteQuery.JoinClause.Join {
        return .init(
            natural: false,
            method,
            table: .table(.init(table: .init(table: .init(name: joined.table!)))),
            constraint: .condition(.binary(.column(base), .equal, .column(joined)))
        )
    }
    
    /// See `JoinSupporting`.
    public static func queryJoinApply(_ join: SQLiteQuery.JoinClause.Join, to query: inout SQLiteQuery.FluentQuery) {
        query.joins.append(join)
    }
}
