@_exported import FluentKit

@_exported import class NIOKit.ConnectionPool

@_exported import NIOSQLite

public protocol SQLiteDataConvertible {
    init?(sqliteData: SQLiteData)
    var sqliteData: SQLiteData? { get }
}
