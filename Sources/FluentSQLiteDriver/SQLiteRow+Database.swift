extension SQLiteRow: DatabaseRow {
    public func contains(field: FieldKey) -> Bool {
        return self.column(field.description) != nil
    }

    public func decode<T>(
        field: FieldKey,
        as type: T.Type,
        for database: Database
    ) throws -> T where T : Decodable {
        return try self.decode(column: field.description, as: T.self)
    }
}
