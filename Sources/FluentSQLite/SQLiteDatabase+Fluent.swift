import Async
import Debugging
import Foundation
import Fluent
import Service
import SQLite

extension SQLiteDatabase: Database, Service {
    /// See `Database`.
    public typealias Connection = SQLiteConnection

    /// See `Database`.
    public func newConnection(on worker: Worker) -> Future<SQLiteConnection> {
        return self.makeConnection(on: worker)
    }
}

func id(_ type: Any.Type) -> ObjectIdentifier {
    return ObjectIdentifier(type)
}

extension SQLiteDatabase: JoinSupporting {}
