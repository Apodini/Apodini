//
//  ProtoEncoder.swift
//  
//
//  Created by Moritz Schüll on 27.11.20.
//

import Foundation

internal class InternalProtoEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var data = Data()
    var hasContainer = false

    init() { }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        if hasContainer {
            fatalError("Attempt to create new encoding container while encoder already has one")
        }

        self.hasContainer = true
        return KeyedEncodingContainer(KeyedProtoEncodingContainer(using: self, codingPath: codingPath))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        if hasContainer {
            fatalError("Attempt to create new encoding container while encoder already has one")
        }

        self.hasContainer = true
        return UnkeyedProtoEncodingContainer(using: self, codingPath: codingPath)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("Single value encoding not supported yet")
    }

    func append(_ value: Data) {
        data.append(value)
    }

    func getEncoded() throws -> Data {
        data
    }
}

/// Encoder for Protobuffer data.
/// Coforms to `TopLevelEncoder` from `Combine`, however this is currently ommitted due to compatibility issues.
public class ProtoEncoder {
    private var encoder: InternalProtoEncoder?

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = InternalProtoEncoder()
        try value.encode(to: encoder)
        return try encoder.getEncoded()
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        let encoder = InternalProtoEncoder()
        self.encoder = encoder
        return encoder.unkeyedContainer()
    }

    public func getResult() throws -> Data {
        guard let encoder = encoder else {
            throw ProtoError.encodingError("No internal encoder initialized. Call unkeyedContainer() first.")
        }
        return try encoder.getEncoded()
    }
}
