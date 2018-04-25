import Async
import Fluent
import SQLite

extension SQLiteDatabase: TransactionSupporting {
    /// See TransactionSupporting.execute
    public static func execute<R>(transaction: DatabaseTransaction<SQLiteDatabase, R>, on connection: SQLiteConnection) -> Future<R> {
        let promise = connection.eventLoop.newPromise(R.self)

        connection.query(string: "BEGIN TRANSACTION").run().do { _ in
            transaction.run(on: connection).do { result in
                connection.query(string: "COMMIT TRANSACTION").run().transform(to: result).cascade(promise: promise)
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
