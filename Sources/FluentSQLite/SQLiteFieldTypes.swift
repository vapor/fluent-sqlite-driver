/// A type that is capable of being represented by a `SQLiteFieldType`.
///
/// Types conforming to this protocol can be automatically migrated by `FluentSQLite`.
///
/// See `SQLiteType` for more information.
public protocol SQLiteFieldTypeStaticRepresentable {
    /// A `SQLiteFieldType` compatible with this type.
    static var sqliteFieldType: SQLiteFieldType { get }
}

extension FixedWidthInteger {
    /// All `FixedWidthInteger` can be stored in `SQLiteFieldType.integer`
    ///
    /// See `SQLiteFieldTypeStaticRepresentable.sqliteFieldType` for more information.
    public static var sqliteFieldType: SQLiteFieldType { return .integer }
}

extension UInt: SQLiteFieldTypeStaticRepresentable { }
extension UInt8: SQLiteFieldTypeStaticRepresentable { }
extension UInt16: SQLiteFieldTypeStaticRepresentable { }
extension UInt32: SQLiteFieldTypeStaticRepresentable { }
extension UInt64: SQLiteFieldTypeStaticRepresentable { }
extension Int: SQLiteFieldTypeStaticRepresentable { }
extension Int8: SQLiteFieldTypeStaticRepresentable { }
extension Int16: SQLiteFieldTypeStaticRepresentable { }
extension Int32: SQLiteFieldTypeStaticRepresentable { }
extension Int64: SQLiteFieldTypeStaticRepresentable { }

extension Date: SQLiteFieldTypeStaticRepresentable {
    /// `Date`s are stored in SQLite as a double.
    ///
    /// See `SQLiteFieldTypeStaticRepresentable.sqliteFieldType` for more information.
    public static var sqliteFieldType: SQLiteFieldType { return Double.sqliteFieldType }
}

extension BinaryFloatingPoint {
    /// All `BinaryFloatingPoint`s are stored in SQLite as a "REAL" column.
    ///
    /// See `SQLiteFieldTypeStaticRepresentable.sqliteFieldType` for more information.
    public static var sqliteFieldType: SQLiteFieldType { return .real }
}

extension Float: SQLiteFieldTypeStaticRepresentable { }
extension Double: SQLiteFieldTypeStaticRepresentable { }

extension Bool: SQLiteFieldTypeStaticRepresentable {
    /// `Bool`s are stored in SQLite as an `Int`.
    ///
    /// See `SQLiteFieldTypeStaticRepresentable.sqliteFieldType` for more information.
    public static var sqliteFieldType: SQLiteFieldType { return Int.sqliteFieldType }
}

extension UUID: SQLiteFieldTypeStaticRepresentable {
    /// `UUID`s are stored in SQLite as a "BLOB".
    ///
    /// See `SQLiteFieldTypeStaticRepresentable.sqliteFieldType` for more information.
    public static var sqliteFieldType: SQLiteFieldType { return .blob }
}

extension Data: SQLiteFieldTypeStaticRepresentable {
    /// `Data` is stored in SQLite as a "BLOB".
    ///
    /// See `SQLiteFieldTypeStaticRepresentable.sqliteFieldType` for more information.
    public static var sqliteFieldType: SQLiteFieldType { return .blob }
}

extension String: SQLiteFieldTypeStaticRepresentable {
    /// `String`s are stored in SQLite as a "TEXT" column.
    ///
    /// See `SQLiteFieldTypeStaticRepresentable.sqliteFieldType` for more information.
    public static var sqliteFieldType: SQLiteFieldType { return .text }
}

extension URL: SQLiteFieldTypeStaticRepresentable {
    /// `URL`s are stored in SQLite as a `String`.
    ///
    /// See `SQLiteFieldTypeStaticRepresentable.sqliteFieldType` for more information.
    public static var sqliteFieldType: SQLiteFieldType { return String.sqliteFieldType }
}
