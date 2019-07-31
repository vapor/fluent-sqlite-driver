import FluentSQL

extension SQLiteConnection: Database {
    public func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return closure(self)
    }

    public func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        let sql = SQLQueryConverter(delegate: SQLiteConverterDelegate()).convert(query)
        return self.execute(sql: sql) { row in
            try onOutput(row as! DatabaseOutput)
        }.flatMapThrowing {
            switch query.action {
            case .create:
                let row = LastInsertRow(lastAutoincrementID: self.lastAutoincrementID)
                try onOutput(row)
            default: break
            }
        }
    }

    public func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let sql = SQLSchemaConverter(delegate: SQLiteConverterDelegate()).convert(schema)
        return self.execute(sql: sql) { row in
            fatalError("unexpected output")
        }
    }
}

private struct LastInsertRow: DatabaseOutput {
    var description: String {
        return ["id": lastAutoincrementID].description
    }

    let lastAutoincrementID: Int64?

    init(lastAutoincrementID: Int64?) {
        self.lastAutoincrementID = lastAutoincrementID
    }

    func contains(field: String) -> Bool {
        return field == "fluentID"
    }

    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        switch field {
        case "fluentID":
            if T.self is Int?.Type || T.self is Int.Type {
                return Int(self.lastAutoincrementID!) as! T
            } else {
                fatalError("cannot decode last autoincrement type: \(T.self)")
            }
        default:
            throw FluentError.missingField(name: field)
        }
    }
}

