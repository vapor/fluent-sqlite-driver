extension SQLiteError: DatabaseError {
    public var isSyntaxError: Bool {
        switch self.reason {
        case .error:
            return true
        default:
            return false
        }
    }

    public var isConnectionClosed: Bool {
        switch self.reason {
        case .close, .misuse:
            return true
        default:
            return false
        }
    }

    public var isConstraintFailure: Bool {
        switch self.reason {
        case .constraint:
            return true
        default:
            return false
        }
    }
}
