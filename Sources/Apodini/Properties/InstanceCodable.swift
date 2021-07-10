//
//  InstanceCodable.swift
//
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import ApodiniUtils
import NIO

/// An `InstanceEncoder` encodes an object by storing the instances of `_InstanceCodable` objects.
protocol InstanceEncoder: Encoder {
    func singleInstanceEncodingContainer() throws -> SingleValueInstanceEncodingContainer
}

/// An `InstanceDecoder` decodes an object by using a storage of `_InstanceCodable` instances.
protocol InstanceDecoder: Decoder {
    func singleInstanceDecodingContainer() throws -> SingleValueInstanceDecodingContainer
}

/// A container that provides access to a single `_InstanceCodable` instance.
protocol SingleValueInstanceDecodingContainer: SingleValueDecodingContainer {
    func decode<T>(_ type: T.Type) throws -> T
}

/// A container that can store a single `_InstanceCodable` instance.
protocol SingleValueInstanceEncodingContainer: SingleValueEncodingContainer {
    mutating func encode<T>(_ value: T) throws
}

/// An object that can encode/decode itself using a `InstanceEncoder`/`InstanceDecoder` only.
public protocol _InstanceCodable: Codable { }

/// A `Counter` loops through a known sequence of integers indefinitely.
protocol Counter {
    func next() -> Int
}

/// A `Counter` that stores one counter variable for each thread, thus being able to count for multiple
/// threads in parallel.
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

// MARK: FlatInstanceCoding Concept

/// Flat instance coding is a concept for providing fast (faster than what the `Runtime` library can do) mutating
/// access to a struct's properties by first encoding the properties into an array, then performing mutations on
/// that array, and finally decoding the struct from that array.
///
/// Flat instance coding works on three assumptions:
///     1. The order of the calls to `decode`/`encode` and the accompanying container-construction
///     are done in the same order for encoding and decoding.
///     2. Both encoding and decoding are non-failable.
///     3. The only properties that may exist on the encoded/decoded element as well as its recursive
///     children are ``DynamicProperty``, ``Properties`` and `_InstanceCodable` objects.
///     This is the requirement expressed via the ``PropertyIterable`` protocol. Encoding will fail
///     if any other (even `Codable`) object is encountered.
///
/// The whole object is encoded into an array of tuples containing the **instance** and its **name**.
/// The name is calculated from the coding-keys and the `namingStrategy` valid for the current scope.
/// The `namingStrategy` is ``Properties/defaultNamingStrategy`` by default, but is overridden
/// when in the context of a ``DynamicProperty`` or ``Properties`` element (which both provide their
/// own `namingStrategy`.
///
/// On this array `[(String, Any)]`, `Traversable` can be implemented in a very performant manner.


// MARK: FlatInstanceEncoder

class FlatInstanceEncoder: InstanceEncoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    private var store: [(String, Any)] = []
    
    fileprivate var namingStrategy: ([String]) -> String? = Properties.defaultNamingStrategy
    
    init() {}
    
    fileprivate func add(_ value: Any) {
        store.append((namingStrategy(codingPath.map { $0.stringValue })!, value))
    }

    // encoding
    
    func singleInstanceEncodingContainer() throws -> SingleValueInstanceEncodingContainer {
        InstanceEncodingContainer(codingPath: self.codingPath, coder: self)
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        KeyedEncodingContainer(KeyedInstanceEncodingContainer(codingPath: self.codingPath,
                                                              coder: self))
    }
    
    var freezed: FlatInstanceDecoder {
        FlatInstanceDecoder(self.store)
    }
    
    
    // fatals
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
}

// MARK: FlatInstanceDecoder

struct FlatInstanceDecoder: InstanceDecoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
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
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(KeyedInstanceDecodingContainer(codingPath: self.codingPath,
                                                              coder: self))
    }
    
    
    // fatals
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
}

struct KeyedInstanceEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K
    
    var codingPath: [CodingKey]
    
    let coder: FlatInstanceEncoder
    
    func encode<T>(_ value: T, forKey key: K) throws where T: Encodable {
        if T.self is _InstanceCodable.Type {
            coder.codingPath += [key]
            defer { coder.codingPath.removeLast() }
            coder.add(value)
            return
        }
        
        precondition(value is DynamicProperty || value is Properties || value is Properties.EncodingWrapper,
                     "You can only use 'Property's on 'Handler's or other 'PropertyIterable' elements you pass into a 'Delegate'!")
        
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
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        KeyedEncodingContainer(KeyedInstanceEncodingContainer<NestedKey>(codingPath: self.codingPath + [key],
                                                                         coder: self.coder))
    }
    
    // fatals
    
    mutating func encodeNil(forKey key: K) throws {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
    
    mutating func encode<T>(_ value: T, forKey key: K) throws {
        // this should only be called for all the base-types, so never as we always end up with an
        // `InstanceCodable` object
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
    
    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
    
    mutating func superEncoder(forKey key: K) -> Encoder {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
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
    
    func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type,
        forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        KeyedDecodingContainer(KeyedInstanceDecodingContainer<NestedKey>(codingPath: self.codingPath + [key],
                                                                         coder: self.coder))
    }
    
    
    // fatals
    
    var allKeys: [K] {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
    
    func contains(_ key: K) -> Bool {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
    
    func superDecoder() throws -> Decoder {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
}

struct InstanceEncodingContainer: SingleValueInstanceEncodingContainer {
    var codingPath: [CodingKey]
    
    let coder: FlatInstanceEncoder
    
    // encoding
    
    func encode<T>(_ value: T) throws {
        guard T.self is _InstanceCodable.Type else {
            fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
        }
        
        coder.add(value)
    }
    
    // fatals
    
    mutating func encodeNil() throws {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
}

struct InstanceDecodingContainer: SingleValueInstanceDecodingContainer {
    var codingPath: [CodingKey]
    
    let coder: FlatInstanceDecoder
    
    // decoding
    
    func decode<T>(_ type: T.Type) throws -> T {
        coder.next() as! T
    }
    
    // fatals
    
    func decodeNil() -> Bool {
        fatalError("FlatInstanceEncoder/FlatInstanceDecoder was used for encoding/decoding an object that is no valid 'PropertyIterable'.")
    }
}


// MARK: Default Conformance

extension _InstanceCodable {
    /// `Decodable` conformance for `_InstanceCodable` objects.
    public init(from decoder: Decoder) throws {
        guard let instanceCoder = decoder as? InstanceDecoder else {
            fatalError("Tried to decode '_InstanceCodable'  object from a 'Decoder' that is no 'InstanceDecoder'!")
        }

        let container = try instanceCoder.singleInstanceDecodingContainer()
        self = try container.decode(Self.self)
    }

    /// `Encodable` conformance for `_InstanceCodable` objects.
    public func encode(to encoder: Encoder) throws {
        guard let instanceCoder = encoder as? InstanceEncoder else {
            fatalError("Tried to encode '_InstanceCodable'  object to a 'Encoder' that is no 'InstanceEncoder'!")
        }

        var container = try instanceCoder.singleInstanceEncodingContainer()
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
            elements[key] = try type.init(from: decoder) as? Property
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
