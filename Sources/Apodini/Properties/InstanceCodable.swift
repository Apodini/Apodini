//
//  InstanceCodable.swift
//
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation

protocol InstanceCoder: Encoder, Decoder {
    func singleInstanceDecodingContainer() throws -> SingleValueInstanceDecodingContainer
    func singleInstanceEncodingContainer() throws -> SingleValueInstanceEncodingContainer
}

protocol SingleValueInstanceDecodingContainer: SingleValueDecodingContainer {
    func decode<T>(_ type: T.Type) throws -> T
}

protocol SingleValueInstanceEncodingContainer: SingleValueEncodingContainer {
    mutating func encode<T>(_ value: T) throws
}

public protocol InstanceCodable: Codable { }

enum InstanceCodingError: Error {
    case instantializedUsingNonInstanceCoder
    case encodedUsingNonInstanceCoder
    case notImplemented
    case badType
}

extension InstanceCodable {
    public init(from decoder: Decoder) throws {
        guard let ic = decoder as? InstanceCoder else {
            throw InstanceCodingError.instantializedUsingNonInstanceCoder
        }

        let container = try ic.singleInstanceDecodingContainer()
        self = try container.decode(Self.self)
    }

    public func encode(to encoder: Encoder) throws {
        guard let ic = encoder as? InstanceCoder else {
            throw InstanceCodingError.encodedUsingNonInstanceCoder
        }

        var container = try ic.singleInstanceEncodingContainer()
        try container.encode(self)
    }
}

// MARK: Mutator

private protocol InstanceCoderStorage {
    var single: InstanceContainer.Value { get nonmutating set }

    func setKeyed<K: CodingKey>(_ value: KeyedInstanceContainer<K>.Value)

    func getKeyed<K: CodingKey>(_ type: K.Type) -> KeyedInstanceContainer<K>.Value
}

class Mutator: InstanceCoder, InstanceCoderStorage {
    var codingPath: [CodingKey] = [] // implementing that could become the real struggle

    var userInfo: [CodingUserInfoKey : Any] = [:]

    private var store: [Any] = []

    private var count: Int = -1

    init() { }

    fileprivate var single: InstanceContainer.Value {
        get {
            store[count == -1 ? store.count - 1 : count] as! InstanceContainer.Value
        }
        set {
            store[store.count - 1] = newValue as Any
        }
    }

    fileprivate func getKeyed<K: CodingKey>(_ type: K.Type) -> KeyedInstanceContainer<K>.Value {
        store[count == -1 ? store.count - 1 : count] as! KeyedInstanceContainer<K>.Value
    }

    fileprivate func setKeyed<K: CodingKey>(_ value: KeyedInstanceContainer<K>.Value) {
        store[store.count - 1] = value
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        store.append(KeyedInstanceContainer<Key>.Value(count: -1, array: []))
        return KeyedEncodingContainer(KeyedInstanceContainer(codingPath: self.codingPath, store: self))
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        count += 1
        return KeyedDecodingContainer(KeyedInstanceContainer(codingPath: self.codingPath, store: self))
    }

    func singleInstanceEncodingContainer() throws -> SingleValueInstanceEncodingContainer {
        store.append(InstanceContainer.Value.none as Any)
        return InstanceContainer(store: self, codingPath: self.codingPath)
    }

    func singleInstanceDecodingContainer() throws -> SingleValueInstanceDecodingContainer {
        count += 1
        return InstanceContainer(store: self, codingPath: self.codingPath)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError() // UnkeyedInstanceEncodingContainer(injector: self)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError() // think that won't be needed InstanceContainer(injector: self)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError() // UnkeyedInstanceDecodingContainer(injector: self)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError() // think that won't be needed InstanceContainer(injector: self)
    }

    func reset() {
        self.count = 0
    }
}

// MARK: KeyedInstanceContainer

private struct KeyedInstanceContainer<K: CodingKey>: KeyedEncodingContainerProtocol, KeyedDecodingContainerProtocol, InstanceCoderStorage {
    enum Element {
        case value(InstanceCodable?)
        case container(Any)
    }

    typealias Key = K

    typealias Value = (count: Int, array: [(key: K, value: Element)])

    var codingPath: [CodingKey]

    let store: InstanceCoderStorage

    var count: Int {
        get {
            store.getKeyed(K.self).count
        }
        nonmutating set {
            store.setKeyed((newValue, store.getKeyed(K.self).array))
        }
    }

    var instances: [(key: K, value: Element)] {
        get {
            store.getKeyed(K.self).array
        }
        nonmutating set {
            store.setKeyed((store.getKeyed(K.self).count, newValue))
        }
    }



    var single: InstanceContainer.Value {
        get {
            guard case let .container(container) = instances[count == -1 ? instances.count - 1 : count].value else {
                fatalError()
            }
            return container as! InstanceContainer.Value
        }
        nonmutating set {
            instances[instances.count - 1] = (instances[instances.count - 1].key, .container(newValue as Any))
        }
    }

    func getKeyed<K: CodingKey>(_ type: K.Type) -> KeyedInstanceContainer<K>.Value {
        guard case let .container(container) = instances[count == -1 ? instances.count - 1 : count].value else {
            fatalError()
        }
        return container as! KeyedInstanceContainer<K>.Value
    }

    func setKeyed<K: CodingKey>(_ value: KeyedInstanceContainer<K>.Value) {
        instances[instances.count - 1] = (instances[instances.count - 1].key, .container(value as Any))
    }



    var allKeys: [K] {
        instances.map(\.key)
    }

    func contains(_ key: K) -> Bool {
        instances.contains(where: { (instanceKey, _) in
            key.stringValue == instanceKey.stringValue
        })
    }

    mutating func encodeNil(forKey key: K) throws {
        instances.append((key, .value(nil)))
    }

    func decodeNil(forKey key: K) throws -> Bool {
        count += 1
        guard case let (foundKey, .value(value)) = instances[count], key.stringValue == foundKey.stringValue else {
            fatalError()
        }
        return value == nil
    }

    mutating func encode<T>(_ value: T, forKey key: K) throws {
        instances.append((key, .value((value as! InstanceCodable))))
    }

    func decode<T>(_ type: T.Type, forKey key: K) throws -> T {
        count += 1
        guard case let (foundKey, .value(.some(value))) = instances[count], key.stringValue == foundKey.stringValue else {
            fatalError()
        }
        return value as! T
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        instances.append((key, .container(KeyedInstanceContainer<NestedKey>.Value(count: -1, array: []))))
        return KeyedEncodingContainer(KeyedInstanceContainer<NestedKey>(codingPath: self.codingPath + [key], store: self))
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        count += 1
        return KeyedDecodingContainer(KeyedInstanceContainer<NestedKey>(codingPath: self.codingPath + [key], store: self))
    }

    mutating func superEncoder() -> Encoder {
        fatalError()
    }

    mutating func superEncoder(forKey key: K) -> Encoder {
        fatalError()
    }

    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
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

// MARK: InstanceContainer

private struct InstanceContainer: SingleValueInstanceDecodingContainer, SingleValueInstanceEncodingContainer {
    typealias Value = InstanceCodable?

    let store: InstanceCoderStorage

    var instance: Value {
        get {
            store.single
        }
        nonmutating set {
            store.single = newValue
        }
    }

    var codingPath: [CodingKey]

    func decode<T>(_ type: T.Type) throws -> T {
        guard let typed = instance as? T else {
            throw InstanceCodingError.badType
        }

        return typed
    }

    mutating func encode<T>(_ value: T) throws {
        guard let typed = value as? InstanceCodable else {
            throw InstanceCodingError.notImplemented
        }

        instance = typed
    }

    func decodeNil() -> Bool {
        instance == nil
    }

    mutating func encodeNil() throws {
        instance = nil
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
//
//// MARK: UnkeyedInstanceDecodingContainer
//
//struct UnkeyedInstanceDecodingContainer<Target>: UnkeyedDecodingContainer {
//    let injector: Mutator<Target>
//
//    var codingPath: [CodingKey] {
//        get {
//            injector.codingPath
//        }
//        set {
//            injector.codingPath = newValue
//        }
//    }
//
//    var count: Int? = nil
//
//    var isAtEnd: Bool = false
//
//    var currentIndex: Int = 0
//
//    mutating func decodeNil() throws -> Bool {
//        false
//    }
//
//    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
//        try injector.container(keyedBy: type)
//    }
//
//    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
//        try injector.unkeyedContainer()
//    }
//
//    mutating func superDecoder() throws -> Decoder {
//        injector
//    }
//
//    mutating func decode<T>(_ type: T.Type) throws -> T {
////        print("UnkeyedInstanceDecodingContainer.decode \(type)")
////        print(injector.store)
//        guard T.self is InstanceCodable.Type else {
//            throw InstanceCodingError.notImplemented
//        }
//
//        let next = injector.store[injector.count]
//        injector.count += 1
//
//        guard let typed = next as? T else {
//            throw InstanceCodingError.badType
//        }
//
//        if var element = typed as? Target {
//            try injector.mutate(&element)
//            return element as! T
//        } else {
//            return typed
//        }
//    }
//}
//
//// MARK: UnkeyedInstanceEncodingContainer
//
//struct UnkeyedInstanceEncodingContainer<Target>: UnkeyedEncodingContainer {
//    let injector: Mutator<Target>
//
//    var codingPath: [CodingKey] {
//        get {
//            injector.codingPath
//        }
//        set {
//            injector.codingPath = newValue
//        }
//    }
//
//    var count: Int = 0
//
//    mutating func encodeNil() throws {
//        throw InstanceCodingError.notImplemented
//    }
//
//    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
//        injector.container(keyedBy: keyType)
//    }
//
//    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
//        injector.unkeyedContainer()
//    }
//
//    mutating func superEncoder() -> Encoder {
//        injector
//    }
//
//    mutating func encode<T>(_ value: T) throws {
////        print("UnkeyedInstanceEncodingContainer.encode \(value)")
//        guard let typed = value as? InstanceCodable else {
//            throw InstanceCodingError.notImplemented
//        }
//
//        injector.store.append(typed)
//    }
//}
