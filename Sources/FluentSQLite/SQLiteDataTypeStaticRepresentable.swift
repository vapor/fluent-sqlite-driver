/// A type that is capable of being represented by a `SQLiteFieldType`.
///
/// Types conforming to this protocol can be automatically migrated by `FluentSQLite`.
///
/// See `SQLiteType` for more information.
public protocol SQLiteDataTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    static var sqliteFieldType: SQLiteDataType { get }
}

extension FixedWidthInteger {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return .integer }
}

extension UInt: SQLiteDataTypeStaticRepresentable { }
extension UInt8: SQLiteDataTypeStaticRepresentable { }
extension UInt16: SQLiteDataTypeStaticRepresentable { }
extension UInt32: SQLiteDataTypeStaticRepresentable { }
extension UInt64: SQLiteDataTypeStaticRepresentable { }
extension Int: SQLiteDataTypeStaticRepresentable { }
extension Int8: SQLiteDataTypeStaticRepresentable { }
extension Int16: SQLiteDataTypeStaticRepresentable { }
extension Int32: SQLiteDataTypeStaticRepresentable { }
extension Int64: SQLiteDataTypeStaticRepresentable { }

extension Date: SQLiteDataTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return Double.sqliteFieldType }
}

extension BinaryFloatingPoint {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return .real }
}

extension Float: SQLiteDataTypeStaticRepresentable { }
extension Double: SQLiteDataTypeStaticRepresentable { }

extension Bool: SQLiteDataTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return Int.sqliteFieldType }
}

extension UUID: SQLiteDataTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return .blob }
}

extension Data: SQLiteDataTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return .blob }
}

extension String: SQLiteDataTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return .text }
}

extension URL: SQLiteDataTypeStaticRepresentable {
    /// See `SQLiteFieldTypeStaticRepresentable`.
    public static var sqliteFieldType: SQLiteDataType { return String.sqliteFieldType }
}
