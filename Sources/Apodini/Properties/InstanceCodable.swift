//
//  InstanceCodable.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation

protocol InstanceCoder: Encoder, Decoder {
    func singleInstanceContainer() throws -> SingleValueInstanceContainer
}

protocol SingleValueInstanceContainer: SingleValueDecodingContainer, SingleValueEncodingContainer {
    func decode<T>(_ type: T.Type) throws -> T
    func encode<T>(_ value: T) throws
}

public protocol InstanceCodable: Codable { }

enum InstanceCodingError: Error {
    case instantializedUsingNonInstanceCoder
    case encodedUsingNonInstanceCoder
    case notImplemented
    case badType
}

//@propertyWrapper
//struct Parameter<T>:  ContentInjectable, InstanceCodable {
//    var _value: T?
//
//    var wrappedValue: T {
//        get {
//            guard let value = _value else {
//                fatalError()
//            }
//            return value
//        }
//        set {
//            _value = newValue
//        }
//    }
//
//    init() { }
//
//    mutating func inject(_ value: Content) {
//        switch T.self {
//        case is Int.Type:
//            self._value = (value.int as! T)
//        case is String.Type:
//            self._value = (value.string as! T)
//        case is Int?.Type:
//            self._value = (value.optional as! T)
//        case is SomeClass.Type:
//            self._value = (value.reference as! T)
//        default:
//            fatalError()
//        }
//    }
//
//    init(from decoder: Decoder) throws {
//        guard let ic = decoder as? InstanceCoder else {
//            throw InstanceCodingError.instantializedUsingNonInstanceCoder
//        }
//
//        let container = try ic.singleInstanceContainer()
//        let injectedValue = try container.decode(Parameter<T>.self)
//
//        self = injectedValue
//    }
//
//    func encode(to encoder: Encoder) throws {
//        guard let ic = encoder as? InstanceCoder else {
//            throw InstanceCodingError.encodedUsingNonInstanceCoder
//        }
//
//        let container = try ic.singleInstanceContainer()
//        try container.encode(self)
//    }
//}

extension Property {
    public init(from decoder: Decoder) throws {
        guard let ic = decoder as? InstanceCoder else {
            throw InstanceCodingError.instantializedUsingNonInstanceCoder
        }

        let container = try ic.singleInstanceContainer()
        self = try container.decode(Self.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        guard let ic = encoder as? InstanceCoder else {
            throw InstanceCodingError.encodedUsingNonInstanceCoder
        }

        let container = try ic.singleInstanceContainer()
        try container.encode(self)
    }
}

typealias Activator = Mutator<Activatable>

extension Activator {
    convenience init() {
        self.init { activatable in
            activatable.activate()
        }
    }
}

// MARK: Mutator

class Mutator<Target>: InstanceCoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    internal fileprivate(set) var store: [InstanceCodable] = []
    
    fileprivate var count: Int = 0
    
    fileprivate var mutation: (inout Target) throws -> Void
    
    init(_ mutation: @escaping (inout Target) throws -> Void) {
        self.mutation = mutation
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        KeyedEncodingContainer(KeyedInstanceContainer(injector: self))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        UnkeyedInstanceEncodingContainer(injector: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        InstanceContainer(injector: self)
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(KeyedInstanceContainer(injector: self))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        UnkeyedInstanceDecodingContainer(injector: self)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        InstanceContainer(injector: self)
    }
    
    func singleInstanceContainer() throws -> SingleValueInstanceContainer {
        InstanceContainer(injector: self)
    }
    
    func mutate(_ element: inout Target) throws {
        try mutation(&element)
    }
    
    func reset() {
        self.count = 0
    }
}

// MARK: UnkeyedInstanceDecodingContainer

struct UnkeyedInstanceDecodingContainer<Target>: UnkeyedDecodingContainer {
    let injector: Mutator<Target>
    
    var codingPath: [CodingKey] {
        get {
            injector.codingPath
        }
        set {
            injector.codingPath = newValue
        }
    }
    
    var count: Int? = nil
    
    var isAtEnd: Bool = false
    
    var currentIndex: Int = 0
    
    mutating func decodeNil() throws -> Bool {
        false
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        try injector.container(keyedBy: type)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try injector.unkeyedContainer()
    }
    
    mutating func superDecoder() throws -> Decoder {
        injector
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T {
//        print("UnkeyedInstanceDecodingContainer.decode \(type)")
//        print(injector.store)
        guard T.self is InstanceCodable.Type else {
            throw InstanceCodingError.notImplemented
        }
        
        let next = injector.store[injector.count]
        injector.count += 1
        
        guard let typed = next as? T else {
            throw InstanceCodingError.badType
        }
        
        if var element = typed as? Target {
            try injector.mutate(&element)
            return element as! T
        } else {
            return typed
        }
    }
}

// MARK: UnkeyedInstanceEncodingContainer

struct UnkeyedInstanceEncodingContainer<Target>: UnkeyedEncodingContainer {
    let injector: Mutator<Target>
    
    var codingPath: [CodingKey] {
        get {
            injector.codingPath
        }
        set {
            injector.codingPath = newValue
        }
    }
    
    var count: Int = 0
    
    mutating func encodeNil() throws {
        throw InstanceCodingError.notImplemented
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        injector.container(keyedBy: keyType)
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        injector.unkeyedContainer()
    }
    
    mutating func superEncoder() -> Encoder {
        injector
    }
    
    mutating func encode<T>(_ value: T) throws {
//        print("UnkeyedInstanceEncodingContainer.encode \(value)")
        guard let typed = value as? InstanceCodable else {
            throw InstanceCodingError.notImplemented
        }
        
        injector.store.append(typed)
    }
}

// MARK: KeyedInstanceContainer

struct KeyedInstanceContainer<K: CodingKey, Target>: KeyedEncodingContainerProtocol, KeyedDecodingContainerProtocol {
    mutating func encodeNil(forKey key: K) throws {
        throw InstanceCodingError.notImplemented
    }
    
    mutating func encode<T>(_ value: T, forKey key: K) throws {
//        print("KeyedInstanceContainer.encode \(value) forkey \(key)")
        guard let typed = value as? InstanceCodable else {
            throw InstanceCodingError.notImplemented
        }
        
        injector.store.append(typed)
    }
    
    var allKeys: [K] {
//        print("allKeys")
        return []
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        injector.container(keyedBy: keyType)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        injector.unkeyedContainer()
    }
    
    mutating func superEncoder() -> Encoder {
        injector
    }
    
    mutating func superEncoder(forKey key: K) -> Encoder {
        injector
    }
    
    func contains(_ key: K) -> Bool {
//        print("contains \(key)")
        return false
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        false
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T {
//        print("KeyedInstanceContainer.decode \(type)")
//        print(injector.store)
        guard T.self is InstanceCodable.Type else {
            throw InstanceCodingError.notImplemented
        }
        
        let next = injector.store[injector.count]
        injector.count += 1
        
        guard let typed = next as? T else {
            throw InstanceCodingError.badType
        }
        
        if var element = typed as? Target {
            try injector.mutate(&element)
            return element as! T
        } else {
            return typed
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        try injector.container(keyedBy: type)
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        try injector.unkeyedContainer()
    }
    
    func superDecoder() throws -> Decoder {
        injector
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        injector
    }
    
    typealias Key = K
    
    let injector: Mutator<Target>
    
    var codingPath: [CodingKey] {
        get {
            injector.codingPath
        }
        set {
            injector.codingPath = newValue
        }
    }
}

// MARK: InstanceContainer

struct InstanceContainer<Target>: SingleValueInstanceContainer {
    let injector: Mutator<Target>
    
    var codingPath: [CodingKey] {
        get {
            injector.codingPath
        }
        set {
            injector.codingPath = newValue
        }
    }
    
    func decode<T>(_ type: T.Type) throws -> T {
//        print("InstanceContainer.decode \(type)")
//        print(injector.store)
        guard T.self is InstanceCodable.Type else {
            throw InstanceCodingError.notImplemented
        }
        
        let next = injector.store[injector.count]
        injector.count += 1
        
        guard let typed = next as? T else {
            throw InstanceCodingError.badType
        }
        
        if var element = typed as? Target {
            try injector.mutate(&element)
            return element as! T
        } else {
            return typed
        }
    }
    
    func encode<T>(_ value: T) throws {
//        print("InstanceContainer.encode \(value)")
//        print(injector.store)
        guard let typed = value as? InstanceCodable else {
            throw InstanceCodingError.notImplemented
        }
        
        injector.store.append(typed)
    }
    
    func decodeNil() -> Bool {
        false
    }
    
    mutating func encodeNil() throws {
        throw InstanceCodingError.notImplemented
    }
}

//extension InstanceCodableBasedHandler: ContentInjectable {
//    mutating func inject(_ content: Content) throws {
//        var injector: Injector
//        if let i = Self.injector {
//            injector = i
//        } else {
//            injector = Injector(valueToInject: Content(string: "x", int: -1, optional: -1, reference: SomeClass(string: "x")))
//            try self.encode(to: injector)
//            Self.injector = injector
//        }
//        injector.valueToInject = content
//        self = try InstanceCodableBasedHandler(from: injector)
//        injector.reset()
//    }
//}
