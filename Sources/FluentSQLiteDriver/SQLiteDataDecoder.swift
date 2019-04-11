import Foundation

#warning("TODO: move to codable kit")
struct DecoderUnwrapper: Decodable {
    let decoder: Decoder
    init(from decoder: Decoder) {
        self.decoder = decoder
    }
}

public struct SQLiteDataDecoder {
    public init() {}

    public func decode<T>(_ type: T.Type, from data: SQLiteData) throws -> T
        where T: Decodable
    {
        return try _decode(T.self, decoder: _Decoder(data: data), data: data, codingPath: [])
    }

    #warning("TODO: finish implementing")

    private final class _Decoder: Decoder {
        var codingPath: [CodingKey] {
            return []
        }

        var userInfo: [CodingUserInfoKey : Any] {
            return [:]
        }

        let data: SQLiteData
        init(data: SQLiteData) {
            self.data = data
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            fatalError()
        }

        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            #warning("TODO: use NIOFoundationCompat")
            guard case .blob(var buffer) = self.data else {
                fatalError()
            }
            let data = buffer.readBytes(length: buffer.readableBytes)!
            let unwrapper = try JSONDecoder().decode(DecoderUnwrapper.self, from: Data(data))
            return try unwrapper.decoder.container(keyedBy: Key.self)
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            return _SingleValueDecoder(self)
        }
    }

    private struct _SingleValueDecoder: SingleValueDecodingContainer {
        var codingPath: [CodingKey] {
            return self.decoder.codingPath
        }
        let decoder: _Decoder
        init(_ decoder: _Decoder) {
            self.decoder = decoder
        }

        func decodeNil() -> Bool {
            return self.decoder.data == .null
        }

        func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            return try _decode(T.self, decoder: self.decoder, data: self.decoder.data, codingPath: self.codingPath)
        }
    }
}


private func _decode<T>(_ type: T.Type, decoder: Decoder, data: SQLiteData, codingPath: [CodingKey]) throws -> T where T: Decodable {
    if let type = type as? SQLiteDataConvertible.Type {
        guard let decoded = type.init(sqliteData: data) else {
            throw DecodingError.typeMismatch(T.self, DecodingError.Context.init(codingPath: codingPath, debugDescription: "Could not convert \(data) to \(T.self)"))
        }
        return decoded as! T
    } else {
        return try T.init(from: decoder)
    }
}
