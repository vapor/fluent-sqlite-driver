/// A SQLite database model.
/// See `Fluent.Model`.
public protocol SQLiteModel: Model where Self.Database == SQLiteDatabase, Self.ID == Int {
    /// This SQLite Model's unique identifier.
    var id: ID? { get set }
}

extension SQLiteModel {
    /// See `Model`
    public static var idKey: IDKey { return \.id }
}

/// A SQLite database pivot.
/// See `Fluent.Pivot`.
public protocol SQLitePivot: Pivot, SQLiteModel { }

/// A SQLite database model.
/// See `Fluent.Model`.
public protocol SQLiteUUIDModel: Model where Self.Database == SQLiteDatabase, Self.ID == UUID {
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
public protocol SQLiteStringModel: Model where Self.Database == SQLiteDatabase, Self.ID == String {
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
