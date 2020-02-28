extension SQLiteRow: DatabaseOutput {
    public func schema(_ schema: String) -> DatabaseOutput {
        SchemaOutput(row: self, schema: schema)
    }

    public func contains(_ path: [FieldKey]) -> Bool {
        self.column(self.columnName(path)) != nil
    }

    public func decode<T>(_ path: [FieldKey], as type: T.Type) throws -> T
        where T: Decodable
    {
        try self.decode(column: self.columnName(path), as: T.self)
    }

    func columnName(_ path: [FieldKey]) -> String {
        path.map { $0.description }.joined(separator: "_")
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

    func contains(_ path: [FieldKey]) -> Bool {
        self.row.contains(column: self.schema + "_" + self.row.columnName(path))
    }

    func decode<T>(_ path: [FieldKey], as type: T.Type) throws -> T
        where T : Decodable
    {
        try self.row.decode(column: self.schema + "_" + self.row.columnName(path), as: T.self)
    }
}
