import Async
import Debugging
import Foundation
import Fluent
import Service
import SQLite

extension SQLiteDatabase: Service { }

func id(_ type: Any.Type) -> ObjectIdentifier {
    return ObjectIdentifier(type)
}

extension SQLiteDatabase: JoinSupporting {}
