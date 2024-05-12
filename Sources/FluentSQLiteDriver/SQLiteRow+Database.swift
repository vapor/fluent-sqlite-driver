import Foundation
import SQLiteNIO
import SQLiteKit
import FluentKit

extension SQLiteRow {
    /// Returns a `DatabaseOutput` for this row.
    /// 
    /// - Parameter decoder: An `SQLiteDataDecoder` used to translate `SQLiteData` values into output values.
    /// - Returns: A `DatabaseOutput` instance.
    func databaseOutput(decoder: SQLiteDataDecoder) -> any DatabaseOutput {
        SQLiteDatabaseOutput(row: self.sql(decoder: decoder), schema: nil)
    }
}

/// A `DatabaseOutput` implementation for `SQLiteRow`s.
private struct SQLiteDatabaseOutput: DatabaseOutput {
    /// The underlying row.
    let row: any SQLRow
    
    /// The most recently set schema value (see `DatabaseOutput.schema(_:)`).
    let schema: String?
    
    private func column(for key: FieldKey) -> String {
        (self.schema.map { FieldKey.prefix(.prefix(.string($0), "_"), key) } ?? key).description
    }

    func schema(_ schema: String) -> DatabaseOutput {
        SQLiteDatabaseOutput(row: self.row, schema: schema)
    }

    func contains(_ key: FieldKey) -> Bool {
        self.row.contains(column: self.column(for: key))
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.row.decodeNil(column: self.column(for: key))
    }

    func decode<T: Decodable>(_ key: FieldKey, as type: T.Type) throws -> T {
        try self.row.decode(column: self.column(for: key), as: T.self)
    }
    
    var description: String { "" }
}
