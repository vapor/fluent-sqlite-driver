import Async

extension SQLiteDatabase: ReferenceSupporting {
    /// ReferenceSupporting.enableReferences
    public static func enableReferences(on connection: SQLiteConnection) -> Future<Void> {
        return connection.query(string: "PRAGMA foreign_keys = ON;").run()
    }

    /// ReferenceSupporting.disableReferences
    public static func disableReferences(on connection: SQLiteConnection) -> Future<Void> {
        return connection.query(string: "PRAGMA foreign_keys = OFF;").run()
    }
}
