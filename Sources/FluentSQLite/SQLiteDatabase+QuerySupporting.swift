extension SQLiteDatabase: QuerySupporting {
    /// See `QuerySupporting`.
    public typealias Query = FluentSQLiteQuery
    
    /// See `QuerySupporting`.
    public typealias Output = [SQLiteColumn: SQLiteData]
    
    /// See `QuerySupporting`.
    public typealias QueryAction = FluentSQLiteQueryStatement
    
    /// See `QuerySupporting`.
    public typealias QueryAggregate = String
    
    /// See `QuerySupporting`.
    public typealias QueryData = [String: SQLiteExpression]
    
    /// See `QuerySupporting`.
    public typealias QueryField = SQLiteColumnIdentifier
    
    /// See `QuerySupporting`.
    public typealias QueryFilterMethod = SQLiteBinaryOperator
    
    /// See `QuerySupporting`.
    public typealias QueryFilterValue = SQLiteExpression
    
    /// See `QuerySupporting`.
    public typealias QueryFilter = SQLiteExpression
    
    /// See `QuerySupporting`.
    public typealias QueryFilterRelation = SQLiteBinaryOperator
    
    /// See `QuerySupporting`.
    public typealias QueryKey = SQLiteSelectExpression
    
    /// See `QuerySupporting`.
    public typealias QuerySort = SQLiteOrderBy
    
    /// See `QuerySupporting`.
    public typealias QuerySortDirection = SQLiteDirection
    
    /// See `QuerySupporting`.
    public static func queryExecute(_ fluent: Query, on conn: SQLiteConnection, into handler: @escaping ([SQLiteColumn : SQLiteData], SQLiteConnection) throws -> ()) -> Future<Void> {
        let query: SQLiteQuery
        switch fluent.statement {
        case ._insert:
            var insert: SQLiteInsert = .insert(fluent.table)
            
            if let firstRow = fluent.values.first {
                insert.columns.append(contentsOf: firstRow.columns())
                fluent.values.forEach { value in
                    let row = value.sqliteExpression()
                    insert.values.append(row)
                }
            }
            
            query = .insert(insert)
        case ._select:
            var select: SQLiteSelect = .select()
            select.columns = fluent.keys.isEmpty ? [.all] : fluent.keys
            select.tables = [fluent.table]
            select.joins = fluent.joins
            select.predicate = fluent.predicate
            select.orderBy = fluent.orderBy
            select.groupBy = fluent.groupBy
            select.limit = fluent.limit
            select.offset = fluent.offset
            query = .select(select)
        case ._update:
            var update: SQLiteUpdate = .update(fluent.table)
            update.table = fluent.table
            if let row = fluent.values.first {
                update.values = row.map { val in (.identifier(val.key), val.value) }
            }
            update.predicate = fluent.predicate
            query = .update(update)
        case ._delete:
            var delete: SQLiteDelete = .delete(fluent.table)
            delete.predicate = fluent.predicate
            query = .delete(delete)
        }
        return conn.query(query) { try handler($0, conn) }
    }
    
    /// See `QuerySupporting`.
    public static func modelEvent<M>(event: ModelEvent, model: M, on conn: SQLiteConnection) -> EventLoopFuture<M> where SQLiteDatabase == M.Database, M : Model {
        var copy = model
        switch event {
        case .willCreate:
            if M.ID.self is UUID.Type, copy.fluentID == nil {
                copy.fluentID = UUID() as? M.ID
            }
        case .didCreate:
            if let intType = M.ID.self as? Int64Initializable.Type, copy.fluentID == nil {
                copy.fluentID = conn.lastAutoincrementID.flatMap { intType.init($0) as? M.ID }
            }
        default: break
        }
        return conn.future(copy)
    }
}

internal protocol Int64Initializable {
    init(_ int64: Int64)
}

extension Int: Int64Initializable { }
extension UInt: Int64Initializable { }
extension Int64: Int64Initializable { }
extension UInt64: Int64Initializable { }
extension Int32: Int64Initializable { }
extension UInt32: Int64Initializable { }

extension Dictionary where Key == String, Value == FluentSQLiteQuery.Expression {
    func sqliteExpression() -> [SQLiteExpression] {
        return self.map { pair -> SQLiteExpression in
            switch pair.value {
            case ._literal(let literal):
                switch literal {
                case ._null: return .literal(.default)
                default: return pair.value
                }
            default: return pair.value
            }
        }
    }
    
    func columns() -> [SQLiteColumnIdentifier] {
        return self.map { .column(nil, .identifier($0.key)) }
    }
}
