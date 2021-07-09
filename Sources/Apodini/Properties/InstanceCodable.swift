//
//  InstanceCodable.swift
//
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import ApodiniUtils
import NIO

protocol InstanceEncoder: Encoder {
    func singleInstanceEncodingContainer() throws -> SingleValueInstanceEncodingContainer
}

protocol InstanceDecoder: Decoder {
    func singleInstanceDecodingContainer() throws -> SingleValueInstanceDecodingContainer
}

protocol SingleValueInstanceDecodingContainer: SingleValueDecodingContainer {
    func decode<T>(_ type: T.Type) throws -> T
}

protocol SingleValueInstanceEncodingContainer: SingleValueEncodingContainer {
    mutating func encode<T>(_ value: T) throws
}

public protocol _InstanceCodable: Codable { }

protocol Counter {
    func next() -> Int
}

struct ThreadSpecificCounter: Counter {
    let counter: ThreadSpecificVariable<Box<Int>> = ThreadSpecificVariable()
    
    let count: Int
    
    func next() -> Int {
        if let current = counter.currentValue {
            current.value += 1
            if current.value >= count {
                current.value = 0
            }
            return current.value
        } else {
            counter.currentValue = Box(0)
            return 0
        }
    }
}

// MARK: FlatInstanceEncoder

class FlatInstanceEncoder: InstanceEncoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    private var store: [(String, Any)] = []
    
    fileprivate var namingStrategy: ([String]) -> String? = Properties.defaultNamingStrategy
    
    init() {}
    
    fileprivate func add(_ value: Any) {
        store.append((namingStrategy(codingPath.map{ $0.stringValue })!, value))
    }

    // encoding
    
    func singleInstanceEncodingContainer() throws -> SingleValueInstanceEncodingContainer {
        InstanceEncodingContainer(codingPath: self.codingPath, coder: self)
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        KeyedEncodingContainer(KeyedInstanceEncodingContainer(codingPath: self.codingPath,
                                                              coder: self))
    }
    
    var freezed: FlatInstanceDecoder {
        FlatInstanceDecoder(self.store)
    }
    
    
    // fatals
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError()
    }
}

// MARK: FlatInstanceDecoder

struct FlatInstanceDecoder: InstanceDecoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var store: [(String, Any)]
    
    private let counter: Counter
    
    init(_ store: [(String, Any)]) {
        self.store = store
        self.counter = ThreadSpecificCounter(count: store.count)
    }
    
    fileprivate func next() -> Any {
        store[counter.next()].1
    }
    
    
    // decoding
    
    func singleInstanceDecodingContainer() throws -> SingleValueInstanceDecodingContainer {
        InstanceDecodingContainer(codingPath: self.codingPath, coder: self)
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(KeyedInstanceDecodingContainer(codingPath: self.codingPath,
                                                              coder: self))
    }
    
    
    // fatals
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError()
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError()
    }
}

struct KeyedInstanceEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K
    
    var codingPath: [CodingKey]
    
    let coder: FlatInstanceEncoder
    
    func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        if T.self is _InstanceCodable.Type {
            coder.codingPath += [key]
            defer { coder.codingPath.removeLast() }
            coder.add(value)
            return
        }
        
        precondition(value is DynamicProperty || value is Properties || value is Properties.EncodingWrapper,
               "You can only use 'Property's or 'DynamicProperty's on 'Handler's or values you pass into a 'Delegate'!")
        
        let previousNamingStrategy = coder.namingStrategy
        if let dynamicProperty = value as? DynamicProperty {
            coder.namingStrategy = dynamicProperty.namingStrategy(_:)
        }
        if let properties = value as? Properties {
            coder.namingStrategy = properties.namingStrategy
        }
        defer { coder.namingStrategy = previousNamingStrategy }
        
        coder.codingPath += [key]
        defer { coder.codingPath.removeLast() }
        
        try value.encode(to: coder)
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return KeyedEncodingContainer(KeyedInstanceEncodingContainer<NestedKey>(codingPath: self.codingPath + [key],
                                                                                coder: self.coder))
    }
    
    // fatals
    
    mutating func encodeNil(forKey key: K) throws {
        fatalError()
    }
    
    mutating func encode<T>(_ value: T, forKey key: K) throws {
        // this should only be called for all the base-types, so never as we always end up with an
        // `InstanceCodable` object
        fatalError()
    }
    
    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError()
    }
    
    mutating func superEncoder(forKey key: K) -> Encoder {
        fatalError()
    }
}

struct KeyedInstanceDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    typealias Key = K
    
    var codingPath: [CodingKey]
    
    let coder: FlatInstanceDecoder
    
    // decoding
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        if T.self is _InstanceCodable.Type {
            return coder.next() as! T
        }
        
        var decoder = coder
        decoder.codingPath += [key]
        
        return try type.init(from: decoder)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        return KeyedDecodingContainer(KeyedInstanceDecodingContainer<NestedKey>(codingPath: self.codingPath + [key],
                                                                                coder: self.coder))
    }
    
    
    // fatals
    
    var allKeys: [K] {
        fatalError()
    }
    
    func contains(_ key: K) -> Bool {
        fatalError()
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        fatalError()
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        fatalError()
    }
    
    func superDecoder() throws -> Decoder {
        fatalError()
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        fatalError()
    }
}

struct InstanceEncodingContainer: SingleValueInstanceEncodingContainer {
    var codingPath: [CodingKey]
    
    let coder: FlatInstanceEncoder
    
    // encoding
    
    func encode<T>(_ value: T) throws {
        guard T.self is _InstanceCodable.Type else {
            fatalError()
        }
        
        coder.add(value)
    }
    
    // fatals
    
    mutating func encodeNil() throws {
        fatalError()
    }
}

struct InstanceDecodingContainer: SingleValueInstanceDecodingContainer {
    var codingPath: [CodingKey]
    
    let coder: FlatInstanceDecoder
    
    // decoding
    
    func decode<T>(_ type: T.Type) throws -> T {
        return coder.next() as! T
    }
    
    // fatals
    
    func decodeNil() -> Bool {
        fatalError()
    }
}


// MARK: Default Conformance

extension _InstanceCodable {
    public init(from decoder: Decoder) throws {
        guard let ic = decoder as? InstanceDecoder else {
            fatalError("Tried to decode '_InstanceCodable'  object from a 'Decoder' that is no 'InstanceDecoder'!")
        }

        let container = try ic.singleInstanceDecodingContainer()
        self = try container.decode(Self.self)
    }

    public func encode(to encoder: Encoder) throws {
        guard let ic = encoder as? InstanceEncoder else {
            fatalError("Tried to encode '_InstanceCodable'  object to a 'Encoder' that is no 'InstanceEncoder'!")
        }

        var container = try ic.singleInstanceEncodingContainer()
        try container.encode(self)
    }
}


// MARK: Properties Conformance

extension Properties: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PropertiesElements.self)
        
        let info = try container.decode(PropertiesCodableInformation.self, forKey: .codingInfo)
        
        let instanceContainer = try container.nestedContainer(keyedBy: String.self, forKey: .instances)
        
        var elements = [String: Property]()
        
        for (key, (type, _)) in info.codingInfo {
            let decoder = try instanceContainer.decode(DecoderExtractor.self, forKey: key).decoder
            elements[key] = try (type.init(from: decoder) as! Property)
        }
        
        self.codingInfo = info.codingInfo
        self.namingStrategy = info.namingStrategy
        self.elements = elements
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PropertiesElements.self)
        
        let info = PropertiesCodableInformation(codingInfo: self.codingInfo, namingStrategy: self.namingStrategy)
        
        try container.encode(info, forKey: .codingInfo)
        
        var instanceContainer = container.nestedContainer(keyedBy: String.self, forKey: .instances)
        
        for (key, (_, closure)) in self.codingInfo { // we always use codingInfo for iteration as its order is fixed!
            try instanceContainer.encode(EncodingWrapper(closure: closure, value: elements[key]!),
                                         forKey: key)
        }
    }
    
    struct DecoderExtractor: Decodable {
        let decoder: Decoder
        
        init(from decoder: Decoder) throws {
            self.decoder = decoder
        }
    }
    
    struct EncodingWrapper: Encodable {
        let closure: (Encoder, Property) throws -> Void
        let value: Property
        
        func encode(to encoder: Encoder) throws {
            try closure(encoder, value)
        }
    }
    
    private struct PropertiesCodableInformation: _InstanceCodable {
        let codingInfo: [String: (Decodable.Type, (Encoder, Property) throws -> Void)]
        let namingStrategy: ([String]) -> String?
    }
    
    private enum PropertiesElements: CodingKey {
        case instances
        case codingInfo
    }
}
