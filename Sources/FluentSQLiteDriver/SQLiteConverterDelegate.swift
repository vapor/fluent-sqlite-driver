import FluentSQL

struct SQLiteConverterDelegate: SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> SQLExpression? {
        switch dataType {
        case .string:
            return SQLRaw("TEXT")
        case .datetime:
            return SQLRaw("REAL")
        case .int64:
            return SQLRaw("INTEGER")
        case .enum:
            return SQLRaw("TEXT")
        default: return nil
        }
    }

    func nestedFieldExpression(_ column: String, _ path: [String]) -> SQLExpression {
        let path = path.joined(separator: ".")
         return SQLRaw("JSON_EXTRACT(\(column), '$.\(path)')")
    }
}
