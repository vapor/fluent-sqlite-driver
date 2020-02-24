extension SQLiteRow: DatabaseOutput {
    public func schema(_ schema: String) -> DatabaseOutput {
        SchemaOutput(row: self, schema: schema)
    }

    public func contains(_ field: FieldKey) -> Bool {
        self.column(field.description) != nil
    }

    public func decode<T>(_ field: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
    {
        try self.decode(column: field.description, as: T.self)
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

    func contains(_ field: FieldKey) -> Bool {
        self.row.contains(column: self.schema + "_" + field.description)
    }

    func decode<T>(_ field: FieldKey, as type: T.Type) throws -> T
        where T : Decodable
    {
        try self.row.decode(column: self.schema + "_" + field.description, as: T.self)
    }
}
