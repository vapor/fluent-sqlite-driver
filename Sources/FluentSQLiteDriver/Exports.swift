@_exported import FluentKit
@_exported import SQLiteKit

extension DatabaseID {
    public static var sqlite: DatabaseID {
        return .init(string: "sqlite")
    }
}
