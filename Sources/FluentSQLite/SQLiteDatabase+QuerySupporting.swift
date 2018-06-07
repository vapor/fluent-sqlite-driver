extension SQLiteQuery {
    public struct FluentQuery {
        public enum Statement {
            case insert
            case select
            case update
            case delete
        }
        
        public var statement: Statement
        public var table: TableName
        public var joins: [JoinClause.Join]
        public var keys: [SQLiteQuery.Select.ResultColumn]
        public var values: [String: SQLiteQuery.Expression]
        public var predicate: Expression?
        public var limit: Int?
        public var offset: Int?
        public init(_ statement: Statement, table: TableName) {
            self.statement = statement
            self.table = table
            self.joins = []
            self.keys = []
            self.values = [:]
            self.predicate = nil
            self.limit = nil
            self.offset = nil
        }
    }
}

extension SQLiteDatabase: QuerySupporting {
    /// See `QuerySupporting`.
    public typealias Query = SQLiteQuery.FluentQuery
    
    /// See `QuerySupporting`.
    public typealias Output = [SQLiteColumn: SQLiteData]
    
    /// See `QuerySupporting`.
    public typealias QueryAction = SQLiteQuery.FluentQuery.Statement
    
    /// See `QuerySupporting`.
    public typealias QueryAggregate = String
    
    /// See `QuerySupporting`.
    public typealias QueryData = [String: SQLiteQuery.Expression]
    
    /// See `QuerySupporting`.
    public typealias QueryField = SQLiteQuery.QualifiedColumnName
    
    /// See `QuerySupporting`.
    public typealias QueryFilterMethod = SQLiteQuery.Expression.BinaryOperator
    
    /// See `QuerySupporting`.
    public typealias QueryFilterValue = SQLiteQuery.Expression
    
    /// See `QuerySupporting`.
    public typealias QueryFilter = SQLiteQuery.Expression
    
    /// See `QuerySupporting`.
    public typealias QueryFilterRelation = SQLiteQuery.Expression.BinaryOperator
    
    /// See `QuerySupporting`.
    public typealias QueryKey = SQLiteQuery.Select.ResultColumn
    
    /// See `QuerySupporting`.
    public typealias QuerySort = String
    
    /// See `QuerySupporting`.
    public typealias QuerySortDirection = SQLiteQuery.Direction
    
    public static func query(_ entity: String) -> SQLiteQuery.FluentQuery {
        return .init(.select, table: .init(name: entity))
    }
    
    public static func queryEntity(for query: SQLiteQuery.FluentQuery) -> String {
        return query.table.name
    }
    
    public static func queryExecute(_ fluent: SQLiteQuery.FluentQuery, on conn: SQLiteConnection, into handler: @escaping ([SQLiteColumn : SQLiteData], SQLiteConnection) throws -> ()) -> Future<Void> {
        let query: SQLiteQuery
        switch fluent.statement {
        case .insert:
            query = .insert(.init(
                with: nil,
                conflictResolution: nil,
                table: .init(table: fluent.table, alias: nil),
                columns: fluent.values.keys.map { .init($0) },
                values: .values([.init(fluent.values.values)]),
                upsert: nil
            ))
        case .select:
            var table: SQLiteQuery.TableOrSubquery
            switch fluent.joins.count {
            case 0: table = .table(.init(table: .init(table: fluent.table, alias: nil), indexing: nil))
            default:
                table = .joinClause(.init(
                    table: .table(.init(table: .init(table: fluent.table, alias: nil), indexing: nil)),
                    joins: fluent.joins
                ))
            }
            
            query = .select(.init(
                with: nil,
                distinct: nil,
                columns: [.all(nil)],
                tables: [table],
                predicate: fluent.predicate
            ))
        case .update:
            query = .update(.init(
                with: nil,
                conflictResolution: nil,
                table: .init(table: .init(table: fluent.table, alias: nil), indexing: nil),
                values: .init(columns: fluent.values.map { (col, expr) in
                    return .init(columns: [.init(col)], value: expr)
                }, predicate: nil),
                predicate: fluent.predicate
            ))
        case .delete:
            query = .delete(.init(
                with: nil,
                table: .init(table: .init(table: fluent.table, alias: nil), indexing: nil),
                predicate: fluent.predicate
            ))
        }
        return conn.query(query) { try handler($0, conn) }
    }
    
    public static func queryDecode<D>(_ output: [SQLiteColumn : SQLiteData], entity: String, as decodable: D.Type, on conn: SQLiteConnection) -> Future<D> where D : Decodable {
        do {
            return try conn.future(output.decode(D.self, from: entity))
        } catch {
            return conn.future(error: error)
        }
    }
    
    public static func queryEncode<E>(_ encodable: E, entity: String) throws -> [String: SQLiteQuery.Expression] where E : Encodable {
        return try SQLiteQueryEncoder().encode(encodable)
    }
    
    public static func modelEvent<M>(event: ModelEvent, model: M, on conn: SQLiteConnection) -> EventLoopFuture<M> where SQLiteDatabase == M.Database, M : Model {
        var copy = model
        switch event {
        case .willCreate: copy.fluentID = UUID() as? M.ID
        default: break
        }
        return conn.future(copy)
    }
    
    public static var queryActionCreate: SQLiteQuery.FluentQuery.Statement {
        return .insert
    }
    
    public static var queryActionRead: SQLiteQuery.FluentQuery.Statement {
        return .select
    }
    
    public static var queryActionUpdate: SQLiteQuery.FluentQuery.Statement {
        return .update
    }
    
    public static var queryActionDelete: SQLiteQuery.FluentQuery.Statement {
        return .delete
    }
    
    public static func queryActionIsCreate(_ action: SQLiteQuery.FluentQuery.Statement) -> Bool {
        switch action {
        case .insert: return true
        default: return false
        }
    }
    
    public static func queryActionApply(_ action: SQLiteQuery.FluentQuery.Statement, to query: inout SQLiteQuery.FluentQuery) {
        query.statement = action
    }
    
    public static var queryAggregateCount: String {
        return "COUNT"
    }
    
    public static var queryAggregateSum: String {
        return "SUM"
    }
    
    public static var queryAggregateAverage: String {
        return "AVG"
    }
    
    public static var queryAggregateMinimum: String {
        return "MIN"
    }
    
    public static var queryAggregateMaximum: String {
        return "MAX"
    }
    
    public static func queryDataSet<E>(_ field: SQLiteQuery.QualifiedColumnName, to data: E, on query: inout SQLiteQuery.FluentQuery)
        where E: Encodable
    {
        query.values[field.name.string] = try! .bind(data)
    }
    
    public static func queryDataApply(_ data: [String: SQLiteQuery.Expression], to query: inout SQLiteQuery.FluentQuery) {
        query.values = data
    }
    
    public static func queryField(_ property: FluentProperty) -> SQLiteQuery.QualifiedColumnName {
        return .init(schema: nil, table: property.entity, name: .init(property.path[0]))
    }
    
    public static var queryFilterMethodEqual: SQLiteQuery.Expression.BinaryOperator {
        return .equal
    }
    
    public static var queryFilterMethodNotEqual: SQLiteQuery.Expression.BinaryOperator {
        return .notEqual
    }
    
    public static var queryFilterMethodGreaterThan: SQLiteQuery.Expression.BinaryOperator {
        return .greaterThan
    }
    
    public static var queryFilterMethodLessThan: SQLiteQuery.Expression.BinaryOperator {
        return .lessThan
    }
    
    public static var queryFilterMethodGreaterThanOrEqual: SQLiteQuery.Expression.BinaryOperator {
        return .greaterThanOrEqual
    }
    
    public static var queryFilterMethodLessThanOrEqual: SQLiteQuery.Expression.BinaryOperator {
        return .lessThanOrEqual
    }
    
    public static var queryFilterMethodInSubset: SQLiteQuery.Expression.BinaryOperator {
        fatalError()
    }
    
    public static var queryFilterMethodNotInSubset: SQLiteQuery.Expression.BinaryOperator {
        fatalError()
    }
    
    public static func queryFilterValue(_ encodables: [Encodable]) -> SQLiteQuery.Expression {
        fatalError()
    }
    
    public static var queryFilterValueNil: SQLiteQuery.Expression {
        return .literal(.null)
    }
    
    public static func queryFilter(_ field: SQLiteQuery.QualifiedColumnName, _ method: SQLiteQuery.Expression.BinaryOperator, _ value: SQLiteQuery.Expression) -> SQLiteQuery.Expression {
        return .binary(.column(field), method, value)
    }
    
    public static func queryFilters(for query: SQLiteQuery.FluentQuery) -> [SQLiteQuery.Expression] {
        if let expression = query.predicate {
            return [expression]
        } else {
            return []
        }
    }
    
    public static func queryFilterApply(_ filter: SQLiteQuery.Expression, to query: inout SQLiteQuery.FluentQuery) {
        query.predicate &= filter
    }
    
    public static var queryFilterRelationAnd: SQLiteQuery.Expression.BinaryOperator {
        return .and
    }
    
    public static var queryFilterRelationOr: SQLiteQuery.Expression.BinaryOperator {
        return .or
    }
    
    public static func queryFilterGroup(_ relation: SQLiteQuery.Expression.BinaryOperator, _ filters: [SQLiteQuery.Expression]) -> SQLiteQuery.Expression {
        var predicate: SQLiteQuery.Expression?
        for next in filters {
            switch relation {
            case .or: predicate |= next
            case .and: predicate &= next
            default: break
            }
        }
        return predicate ?? .expressions([])
    }
    
    public static var queryKeyAll: SQLiteQuery.Select.ResultColumn {
        return .all(nil)
    }
    
    public static func queryAggregate(_ aggregate: String, _ fields: [SQLiteQuery.Select.ResultColumn]) -> SQLiteQuery.Select.ResultColumn {
        let parameters: SQLiteQuery.Expression.Function.Parameters
        switch fields.count {
        case 1:
            switch fields[0] {
            case .all: parameters = .all
            case .expression(let expr, _): parameters = .expressions(distinct: false, [expr])
            }
        default:
            parameters = .expressions(distinct: false, fields.compactMap { field in
                switch field {
                case .all: return nil
                case .expression(let expr, _): return expr
                }
            })
        }
        return .expression(.function(.init(
            name: aggregate,
            parameters: parameters
        )), alias: "fluentAggregate")
    }
    
    public static func queryKey(_ field: SQLiteQuery.QualifiedColumnName) -> SQLiteQuery.Select.ResultColumn {
        return .expression(.column(field), alias: nil)
    }
    
    public static func queryKeyApply(_ key: SQLiteQuery.Select.ResultColumn, to query: inout SQLiteQuery.FluentQuery) {
        query.keys.append(key)
    }
    
    public static func queryRangeApply(lower: Int, upper: Int?, to query: inout SQLiteQuery.FluentQuery) {
        if let upper = upper {
            query.limit = upper - lower
            query.offset = lower
        } else {
            query.offset = lower
        }
    }
    
    public static func querySort(_ field: SQLiteQuery.QualifiedColumnName, _ direction: SQLiteQuery.Direction) -> String {
        fatalError()
    }
    
    public static var querySortDirectionAscending: SQLiteQuery.Direction {
        return .ascending
    }
    
    public static var querySortDirectionDescending: SQLiteQuery.Direction {
        return .descending
    }
    
    public static func querySortApply(_ sort: String, to query: inout SQLiteQuery.FluentQuery) {
        fatalError()
    }
}
