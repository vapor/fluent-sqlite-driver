import SQL

/// A SQLite flavored SQL serializer.
public final class SQLiteSQLSerializer: SQLSerializer {
    public init() { }
  
    public func makeEscapedString(from string: String) -> String {
        return "\"\(string)\""
    }
}
