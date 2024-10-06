import SQLiteNIO
import FluentKit

// Required for Database Error
extension SQLiteError {
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

#if compiler(<6)
extension SQLiteError: DatabaseError { }
#else
extension SQLiteError: @retroactive DatabaseError { }
#endif
