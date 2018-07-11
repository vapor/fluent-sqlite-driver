extension SQLiteDatabase: KeyedCacheSupporting {

    public static func keyedCacheSet<E>(_ key: String, to encodable: E, on conn: SQLiteDatabase.Connection) throws -> Future<Void>
        where E: Encodable
    {
        let data = try JSONEncoder().encode(Encode<E>(data: encodable))

        return CacheEntry<SQLiteDatabase>.query(on: conn).filter(\CacheEntry<SQLiteDatabase>.key == key).first().flatMap { cacheEntry in
            if let cacheEntry = cacheEntry {
                cacheEntry.data = data
                return cacheEntry.save(on: conn).transform(to: ())
            } else {
                return CacheEntry<SQLiteDatabase>(key: key, data: data).create(on: conn).transform(to: ())
            }
        }
    }
}

/// Dictionary wrappers to prevent JSON failures from encoding top-level fragments.
private struct Encode<E>: Encodable where E: Encodable { let data: E }
/// Dictionary wrappers to prevent JSON failures from encoding top-level fragments.
private struct Decode<D>: Decodable where D: Decodable { let data: D }
