import Foundation

extension SQLiteRow: DatabaseOutput {
    public func schema(_ schema: String) -> DatabaseOutput {
        SchemaOutput(row: self, schema: schema)
    }

    public func nested(_ key: FieldKey) throws -> DatabaseOutput {
        guard let data = self.column(self.columnName(key)) else {
            fatalError("Missing nested column: \(key).")
        }
        switch data {
        case .blob:
            fatalError("Decoding nested JSON not yet supported.")
        default:
            fatalError("Unexpected nested column type: \(data).")
        }
    }

    public func contains(_ path: FieldKey) -> Bool {
        self.column(self.columnName(path)) != nil
    }

    public func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.decodeNil(column: self.columnName(key))
    }

    public func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
    {
        try self.decode(column: self.columnName(key), as: T.self)
    }

    func columnName(_ key: FieldKey) -> String {
        switch key {
        case .id:
            return "id"
        case .aggregate:
            return key.description
        case .string(let name):
            return name
        case .prefix(let prefix, let key):
            return self.columnName(prefix) + self.columnName(key)
        }
    }
}

private struct SchemaOutput: DatabaseOutput {
    let row: SQLiteRow
    let schema: String

    var description: String {
        self.row.description
    }

    func schema(_ schema: String) -> DatabaseOutput {
        SchemaOutput(row: self.row, schema: schema)
    }

    func nested(_ key: FieldKey) throws -> DatabaseOutput {
        try self.row.nested(self.key(key))
    }

    func contains(_ key: FieldKey) -> Bool {
        self.row.contains(self.key(key))
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.row.decodeNil(self.key(key))
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T : Decodable
    {
        try self.row.decode(self.key(key), as: T.self)
    }

    func key(_ key: FieldKey) -> FieldKey {
        .prefix(.string(self.schema + "_"), key)
    }
}
