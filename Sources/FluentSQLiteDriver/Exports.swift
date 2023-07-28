#if swift(>=5.8)

@_documentation(visibility: internal) @_exported import FluentKit
@_documentation(visibility: internal) @_exported import SQLiteKit

#else 

@_exported import FluentKit
@_exported import SQLiteKit

#endif

extension DatabaseID {
    public static var sqlite: DatabaseID {
        return .init(string: "sqlite")
    }
}
