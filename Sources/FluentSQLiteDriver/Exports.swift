@_documentation(visibility: internal) @_exported import FluentKit
@_documentation(visibility: internal) @_exported import SQLiteKit

extension DatabaseID {
    public static var sqlite: DatabaseID {
        .init(string: "sqlite")
    }
}
