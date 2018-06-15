/// Types conforming to the `SQLiteType` protocols can be used as properties on `SQLiteModel`s.
///
/// This protocol defines which `SQLiteFieldType` (TEXT, BLOB, etc) a type uses and how it converts to/from `SQLiteData`.
///
/// See `SQLiteEnumType` and `SQLiteJSONType` for more specialized use-cases.
public typealias SQLiteType = Codable & SQLiteFieldTypeStaticRepresentable & SQLiteDataConvertible

// MARK: JSON

/// This protocol makes it easy to declare nested structs on `SQLiteModel`'s that will be stored as JSON-encoded data.
///
///     struct Pet: SQLiteJSONType {
///         var name: String
///     }
///
///     struct User: SQLiteModel, Migration {
///         var id: Int?
///         var pet: Pet
///     }
///
/// The above models will result in the following schema:
///
///     CREATE TABLE `users` (`id` INTEGER PRIMARY KEY, `pet` BLOB NOT NULL)
///
public protocol SQLiteJSONType: SQLiteType { }

/// Default implementations for `SQLiteJSONType`
extension SQLiteJSONType {
    /// Use the `Data`'s `SQLiteFieldType` to store the JSON-encoded data.
    ///
    /// See `SQLiteFieldTypeStaticRepresentable.sqliteFieldType` for more information.
    public static var sqliteFieldType: SQLiteDataType { return Data.sqliteFieldType }

    /// JSON-encode `Self` to `Data`.
    ///
    /// See `SQLiteDataConvertible.convertToSQLiteData()`
    public func convertToSQLiteData() throws -> SQLiteData {
        return try JSONEncoder().encode(self).convertToSQLiteData()
    }

    /// JSON-decode `Data` to `Self`.
    ///
    /// See `SQLiteDataConvertible.convertFromSQLiteData(_:)`
    public static func convertFromSQLiteData(_ data: SQLiteData) throws -> Self {
        return try JSONDecoder().decode(Self.self, from: Data.convertFromSQLiteData(data))
    }
}

// MARK: Enum

/// This type-alias makes it easy to declare nested enum types for your `SQLiteModel`.
///
///     enum PetType: Int, SQLiteEnumType {
///         case cat, dog
///     }
///
/// `SQLiteEnumType` can be used easily with any enum that has a `SQLiteType` conforming `RawValue`.
///
/// You will need to implement custom `ReflectionDecodable` conformance for enums that have non-standard integer
/// values or enums whose `RawValue` is not an integer.
///
///     enum FavoriteTreat: String, SQLiteEnumType {
///         case bone = "b"
///         case tuna = "t"
///         static func reflectDecoded() -> (FavoriteTreat, FavoriteTreat) {
///             return (.bone, .tuna)
///         }
///     }
///
public typealias SQLiteEnumType = SQLiteType & ReflectionDecodable & RawRepresentable

/// Provides a default `SQLiteFieldTypeStaticRepresentable` implementation where the type is also
/// `RawRepresentable` by a `SQLiteFieldTypeStaticRepresentable` type.
extension SQLiteFieldTypeStaticRepresentable
    where Self: RawRepresentable, Self.RawValue: SQLiteFieldTypeStaticRepresentable
{
    /// Use the `RawValue`'s `SQLiteFieldType`.
    ///
    /// See `SQLiteFieldTypeStaticRepresentable.sqliteFieldType` for more information.
    public static var sqliteFieldType: SQLiteDataType { return RawValue.sqliteFieldType }
}

/// Provides a default `SQLiteDataConvertible` implementation where the type is also
/// `RawRepresentable` by a `SQLiteDataConvertible` type.
extension SQLiteDataConvertible
    where Self: RawRepresentable, Self.RawValue: SQLiteDataConvertible
{
    /// See `SQLiteDataConvertible.convertToSQLiteData()`
    public func convertToSQLiteData() throws -> SQLiteData {
        return try rawValue.convertToSQLiteData()
    }

    /// See `SQLiteDataConvertible.convertFromSQLiteData(_:)`
    public static func convertFromSQLiteData(_ data: SQLiteData) throws -> Self {
        guard let e = try self.init(rawValue: .convertFromSQLiteData(data)) else {
            throw FluentSQLiteError(
                identifier: "rawValue",
                reason: "Could not create `\(Self.self)` from: \(data)",
                source: .capture()
            )
        }
        return e
    }
}
