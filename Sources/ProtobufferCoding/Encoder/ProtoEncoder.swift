//
//  ProtoEncoder.swift
//  
//
//  Created by Moritz Schüll on 27.11.20.
//

import Foundation
import Combine


internal class InternalProtoEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    var data = Data()
    var hasContainer = false


    public init() { }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
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
        return data
    }

}

public class ProtoEncoder: TopLevelEncoder {

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = InternalProtoEncoder()
        try value.encode(to: encoder)
        return try encoder.getEncoded()
    }
}
