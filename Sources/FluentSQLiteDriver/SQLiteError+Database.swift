import FluentKit
import SQLiteNIO

// Required for Database Error
extension SQLiteError {
    public var isSyntaxError: Bool {
        switch self.reason {
        case .error, .schema:
            true
        default:
            false
        }
    }

    public var isConnectionClosed: Bool {
        switch self.reason {
        case .misuse, .cantOpen:
            true
        default:
            false
        }
    }

    public var isConstraintFailure: Bool {
        switch self.reason {
        case .constraint, .constraintCheckFailed, .constraintUniqueFailed, .constraintTriggerFailed,
            .constraintNotNullFailed, .constraintCommitHookFailed, .constraintForeignKeyFailed,
            .constraintPrimaryKeyFailed, .constraintUserFunctionFailed, .constraintVirtualTableFailed,
            .constraintUniqueRowIDFailed, .constraintStrictDataTypeFailed, .constraintUpdateTriggerDeletedRow:
            true
        default:
            false
        }
    }
}

#if compiler(<6)
extension SQLiteError: DatabaseError {}
#else
extension SQLiteError: @retroactive DatabaseError {}
#endif
