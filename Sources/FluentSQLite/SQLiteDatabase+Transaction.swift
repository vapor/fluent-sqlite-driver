import Async
import Fluent
import SQLite

extension SQLiteDatabase: TransactionSupporting {
    /// See TransactionSupporting.execute
    public static func execute(transaction: DatabaseTransaction<SQLiteDatabase>, on connection: SQLiteConnection) -> Future<Void> {
        let promise = connection.eventLoop.newPromise(Void.self)

        connection.query(string: "BEGIN TRANSACTION").run().do { _ in
            transaction.run(on: connection).do {
                connection.query(string: "COMMIT TRANSACTION").run().cascade(promise: promise)
            }.catch { err in
                connection.query(string: "ROLLBACK TRANSACTION").run().do { query in
                    // still fail even tho rollback succeeded
                    promise.fail(error: err)
                }.catch { err in
                    print("Rollback failed") // fixme: combine errors here
                    promise.fail(error: err)
                }
            }
        }.catch { error in
            promise.fail(error: error)
        }

        return promise.futureResult
    }
}
