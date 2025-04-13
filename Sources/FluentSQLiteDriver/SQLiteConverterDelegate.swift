import FluentKit
import FluentSQL
import SQLKit

struct SQLiteConverterDelegate: SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> (any SQLExpression)? {
        switch dataType {
        case .string:
            SQLRaw("TEXT")
        case .datetime:
            SQLRaw("REAL")
        case .int64:
            SQLRaw("INTEGER")
        case .enum:
            SQLRaw("TEXT")
        default:
            nil
        }
    }
}
