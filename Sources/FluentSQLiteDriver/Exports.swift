@_exported import FluentKit
@_exported import SQLiteKit

// TODO: deprecate
extension Databases {
    public func sqlite(
        configuration: SQLiteConfiguration = .init(storage: .memory),
        maxConnectionsPerEventLoop: Int = 1,
        as id: DatabaseID = .sqlite
    ) {
        self.use(
            .sqlite(
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop
            ),
            as: id
        )
    }
}

extension DatabaseID {
    public static var sqlite: DatabaseID {
        return .init(string: "sqlite")
    }
}
