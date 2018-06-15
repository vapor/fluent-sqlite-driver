extension SQLiteDatabase: TransactionSupporting {
    public static func transactionExecute<T>(_ transaction: @escaping (SQLiteConnection) throws -> Future<T>, on conn: SQLiteConnection) -> Future<T> {
        return conn.query("BEGIN TRANSACTION").flatMap { results in
            return try transaction(conn).flatMap { res in
                return conn.query("COMMIT TRANSACTION").transform(to: res)
            }.catchFlatMap { error in
                return conn.query("ROLLBACK TRANSACTION").map { results in
                    throw error
                }
            }
        }
    }
}
