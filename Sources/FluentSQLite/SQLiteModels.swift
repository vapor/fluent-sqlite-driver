/// A SQLite database model.
/// See `Fluent.Model`.
public protocol SQLiteModel: _SQLiteModel where Self.ID == Int {
    /// This SQLite Model's unique identifier.
    var id: ID? { get set }
}

/// Base SQLite model protocol.
public protocol _SQLiteModel: SQLiteTable, Model where Self.Database == SQLiteDatabase { }

extension SQLiteModel {
    /// See `Model`
    public static var idKey: IDKey { return \.id }
}

/// A SQLite database pivot.
/// See `Fluent.Pivot`.
public protocol SQLitePivot: Pivot, SQLiteModel { }

/// A SQLite database model.
/// See `Fluent.Model`.
public protocol SQLiteUUIDModel: _SQLiteModel where Self.ID == UUID {
    /// This SQLite Model's unique identifier.
    var id: UUID? { get set }
}

extension SQLiteUUIDModel {
    /// See `Model`
    public static var idKey: IDKey { return \.id }
}

/// A SQLite database pivot.
/// See `Fluent.Pivot`.
public protocol SQLiteUUIDPivot: Pivot, SQLiteUUIDModel { }

/// A SQLite database model.
/// See `Fluent.Model`.
public protocol SQLiteStringModel: _SQLiteModel where Self.ID == String {
    /// This SQLite Model's unique identifier.
    var id: String? { get set }
}

extension SQLiteStringModel {
    /// See `Model`
    public static var idKey: IDKey { return \.id }
}

/// A SQLite database pivot.
/// See `Fluent.Pivot`.
public protocol SQLiteStringPivot: Pivot, SQLiteStringModel { }

/// A SQLite database migration.
/// See `Fluent.Migration`.
public protocol SQLiteMigration: Migration where Self.Database == SQLiteDatabase { }

/// See `SQLTable`.
public protocol SQLiteTable: SQLTable { }
