import FluentSQL
import SQLKit
import FluentKit

struct SQLiteConverterDelegate: SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> (any SQLExpression)? {
        switch dataType {
        case .string:
            return SQLRaw("TEXT")
        case .datetime:
            return SQLRaw("REAL")
        case .int64:
            return SQLRaw("INTEGER")
        case .enum:
            return SQLRaw("TEXT")
        default:
            return nil
        }
    }
}
