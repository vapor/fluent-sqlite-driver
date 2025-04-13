import FluentKit
import Foundation
import SQLiteKit
import SQLiteNIO

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

/// A legacy deprecated conformance of `SQLiteRow` directly to `DatabaseOutput`. This interface exists solely
/// because its absence would be a public API break.
///
/// Do not use these methods.
@available(*, deprecated, message: "Do not use this conformance.")
extension SQLiteNIO.SQLiteRow: FluentKit.DatabaseOutput {
    // See `DatabaseOutput.schema(_:)`.
    public func schema(_ schema: String) -> any DatabaseOutput {
        self.databaseOutput().schema(schema)
    }

    // See `DatabaseOutput.contains(_:)`.
    public func contains(_ key: FieldKey) -> Bool {
        self.databaseOutput().contains(key)
    }

    // See `DatabaseOutput.decodeNil(_:)`.
    public func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.databaseOutput().decodeNil(key)
    }

    // See `DatabaseOutput.decode(_:as:)`.
    public func decode<T: Decodable>(_ key: FieldKey, as: T.Type) throws -> T {
        try self.databaseOutput().decode(key, as: T.self)
    }
}
