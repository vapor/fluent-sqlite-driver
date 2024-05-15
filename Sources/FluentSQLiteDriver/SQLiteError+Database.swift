import SQLiteNIO
import FluentKit

extension SQLiteError: DatabaseError {
    public var isSyntaxError: Bool {
        switch self.reason {
        case .error, .schema:
            return true
        default:
            return false
        }
    }

    public var isConnectionClosed: Bool {
        switch self.reason {
        case .misuse, .cantOpen:
            return true
        default:
            return false
        }
    }

    public var isConstraintFailure: Bool {
        switch self.reason {
        case .constraint, .constraintCheckFailed, .constraintUniqueFailed, .constraintTriggerFailed,
             .constraintNotNullFailed, .constraintCommitHookFailed, .constraintForeignKeyFailed,
             .constraintPrimaryKeyFailed, .constraintUserFunctionFailed, .constraintVirtualTableFailed,
             .constraintUniqueRowIDFailed, .constraintStrictDataTypeFailed, .constraintUpdateTriggerDeletedRow:
            return true
        default:
            return false
        }
    }
}
