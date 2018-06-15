/// A type that is capable of being represented by a `SQLiteFieldType`.
///
/// Types conforming to this protocol can be automatically migrated by `FluentSQLite`.
///
/// See `SQLiteType` for more information.
public protocol SQLiteFieldTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    static var sqliteFieldType: SQLiteDataType { get }
}

extension FixedWidthInteger {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return .integer }
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
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return Double.sqliteFieldType }
}

extension BinaryFloatingPoint {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return .real }
}

extension Float: SQLiteFieldTypeStaticRepresentable { }
extension Double: SQLiteFieldTypeStaticRepresentable { }

extension Bool: SQLiteFieldTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return Int.sqliteFieldType }
}

extension UUID: SQLiteFieldTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return .blob }
}

extension Data: SQLiteFieldTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return .blob }
}

extension String: SQLiteFieldTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return .text }
}

extension URL: SQLiteFieldTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return String.sqliteFieldType }
}
