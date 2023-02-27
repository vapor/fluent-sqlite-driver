#if !BUILDING_DOCC

@_exported import FluentKit
@_exported import SQLiteKit

#else 

import FluentKit
import SQLiteKit

#endif

extension DatabaseID {
    public static var sqlite: DatabaseID {
        return .init(string: "sqlite")
    }
}
