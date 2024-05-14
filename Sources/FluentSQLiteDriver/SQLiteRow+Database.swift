import Foundation
import SQLiteNIO
import SQLiteKit
import FluentKit

extension SQLRow {
    /// Returns a `DatabaseOutput` for this row.
    ///
    /// - Returns: A `DatabaseOutput` instance.
    func databaseOutput() -> some DatabaseOutput {
        SQLRowDatabaseOutput(row: self, schema: nil)
    }
}

/// A `DatabaseOutput` implementation for generic `SQLRow`s. This should really be in FluentSQL.
private struct SQLRowDatabaseOutput: DatabaseOutput {
    /// The underlying row.
    let row: any SQLRow

    /// The most recently set schema value (see `DatabaseOutput.schema(_:)`).
    let schema: String?
    
    // See `CustomStringConvertible.description`.
    var description: String {
        String(describing: self.row)
    }

    /// Apply the current schema (if any) to the given `FieldKey` and convert to a column name.
    private func adjust(key: FieldKey) -> String {
        (self.schema.map { .prefix(.prefix(.string($0), "_"), key) } ?? key).description
    }
    
    // See `DatabaseOutput.schema(_:)`.
    func schema(_ schema: String) -> any DatabaseOutput {
        SQLRowDatabaseOutput(row: self.row, schema: schema)
    }
    
    // See `DatabaseOutput.contains(_:)`.
    func contains(_ key: FieldKey) -> Bool {
        self.row.contains(column: self.adjust(key: key))
    }
    
    // See `DatabaseOutput.decodeNil(_:)`.
    func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.row.decodeNil(column: self.adjust(key: key))
    }
    
    // See `DatabaseOutput.decode(_:as:)`.
    func decode<T: Decodable>(_ key: FieldKey, as: T.Type) throws -> T {
        try self.row.decode(column: self.adjust(key: key), as: T.self)
    }
}
