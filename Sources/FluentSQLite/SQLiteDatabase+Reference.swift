import Async

extension SQLiteDatabase: ReferenceSupporting {
    /// See `ReferenceSupporting`.
    public static func enableReferences(on connection: SQLiteConnection) -> Future<Void> {
        return connection.query(string: "PRAGMA foreign_keys = ON;").run()
    }

    /// See `ReferenceSupporting`.
    public static func disableReferences(on connection: SQLiteConnection) -> Future<Void> {
        return connection.query(string: "PRAGMA foreign_keys = OFF;").run()
    }
}
