infix operator ~=
/// Has prefix
public func ~= <Result>(lhs: KeyPath<Result, String>, rhs: String) -> FilterOperator<SQLiteDatabase, Result> {
    return .make(lhs, .compare(.like), ["%" + rhs])
}
/// Has prefix
public func ~= <Result>(lhs: KeyPath<Result, String?>, rhs: String) -> FilterOperator<SQLiteDatabase, Result> {
    return .make(lhs, .compare(.like), ["%" + rhs])
}

infix operator =~
/// Has suffix.
public func =~ <Result>(lhs: KeyPath<Result, String>, rhs: String) -> FilterOperator<SQLiteDatabase, Result> {
    return .make(lhs, .compare(.like), [rhs + "%"])
}
/// Has suffix.
public func =~ <Result>(lhs: KeyPath<Result, String?>, rhs: String) -> FilterOperator<SQLiteDatabase, Result> {
    return .make(lhs, .compare(.like), [rhs + "%"])
}

infix operator ~~
/// Contains.
public func ~~ <Result>(lhs: KeyPath<Result, String>, rhs: String) -> FilterOperator<SQLiteDatabase, Result> {
    return .make(lhs, .compare(.like), ["%" + rhs + "%"])
}
/// Contains.
public func ~~ <Result>(lhs: KeyPath<Result, String?>, rhs: String) -> FilterOperator<SQLiteDatabase, Result> {
    return .make(lhs, .compare(.like), ["%" + rhs + "%"])
}
