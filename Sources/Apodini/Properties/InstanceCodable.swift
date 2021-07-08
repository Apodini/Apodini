//
//  InstanceCodable.swift
//
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import ApodiniUtils
import NIO

//struct Verifier {
//    @Environment(\.someToken) var token
//
//    @Environment(\.database) var db
//
//    func verify() throws -> AuthenticatedUser {
//        let userid = try checkToken()
//
//        return db.getUserById(userId)
//    }
//
//    private func checkToken() throws -> UUID {
//        // ...
//    }
//}
//
//struct VerifyingHandler<H: Handler>: Handler { // created by DelegatingHandlerInitializer
//    let verifier = Delegate(Verifier(), .required)
//    let handler: Delegate<H>
//
//    func handle() throws -> H.Response {
//        let user = try verifier().verify()
//
//        return try handler.environmentObject(user)().handle()
//    }
//}
//


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

// MARK: Stores

enum Element: CustomDebugStringConvertible {
    case store(ContainerStore)
    case value(Any)
    
    var debugDescription: String {
        switch self {
        case let .store(store):
            return "Element.store(\(store))"
        case let .value(value):
            return "Element.value(\(value))"
        }
    }
}

protocol ContainerStore: CustomDebugStringConvertible {
    // encoding only
    var keyed: KeyedElementStore? { get nonmutating set }
    var single: SingleElementStore? { get nonmutating set }
    
    // decoding only
    func next() -> Any
}

protocol KeyedElementStore: CustomDebugStringConvertible {
    // encoding only
    var current: Element? { get nonmutating set }
    func add<K: CodingKey>(_ key: K)
    
    // decoding only
    /// Loops through all stored `Element`s indefinitely
    func next() -> Element
}

protocol SingleElementStore: CustomDebugStringConvertible {
    // encoding only
    var element: Element? { get nonmutating set }
    
    // decoding only
    /// Loops through all stored `Element`s indefinitely
    func next() -> Element
}



class BaseContainerStore: ContainerStore {
    private var _container: Any? = nil
    
    init() { }
    
    // encoding
    
    var keyed: KeyedElementStore? {
        get {
            guard _container != nil else {
                return nil
            }
            
            return _container as! KeyedElementStore
        }
        set {
            _container = newValue
        }
    }
    
    var single: SingleElementStore? {
        get {
            guard _container != nil else {
                return nil
            }
            
            return _container as! SingleElementStore
        }
        set {
            _container = newValue
        }
    }
    
    // decoding
    
    func next() -> Any {
        _container!
    }
    
    // misc
    
    var debugDescription: String {
        guard let container = _container else {
            return "BaseContainerStore(nil)"
        }
        
        guard let describable = container as? CustomDebugStringConvertible else {
            return "BaseContainerStore(fatal)"
        }
        
        return "BaseContainerStore(\(describable.debugDescription))"
    }
}


struct RecursiveContainerStore: ContainerStore {
    var _container: Any?
    
    let store: SingleElementStore
    
    private var selfCopy: Self {
        get {
            guard let element = store.element else {
                store.element = .store(self)
                return self
            }
            
            guard case let .store(container) = element else {
                fatalError()
            }
            return container as! Self
        }
        nonmutating set {
            store.element = .store(newValue)
        }
    }
    
    // encoding
    
    var keyed: KeyedElementStore? {
        get {
            selfCopy._container as? KeyedElementStore
        }
        nonmutating set {
            var copy = self
            copy._container = newValue
            selfCopy = copy
        }
    }
    
    var single: SingleElementStore? {
        get {
            selfCopy._container as? SingleElementStore
        }
        nonmutating set {
            var copy = self
            copy._container = newValue
            selfCopy = copy
        }
    }
    
    // decoding
    
    func next() -> Any {
        _container!
    }
    
    // misc
    
    var debugDescription: String {
        guard let container = _container else {
            return "RecursiveContainerStore(nil)"
        }
        
        guard let describable = container as? CustomDebugStringConvertible else {
            return "RecursiveContainerStore(fatal)"
        }
        
        return "RecursiveContainerStore(\(describable.debugDescription))"
    }
}

struct PrekeyedSingleElementStore<Key: CodingKey>: SingleElementStore {
    let store: KeyedElementStore
    
    let key: Key
    
    init(store: KeyedElementStore, key: Key) {
        store.add(key)
        self.store = store
        self.key = key
    }
    
    // encoding
    
    var element: Element? {
        get {
            store.current
        }
        nonmutating set {
            store.current = newValue
        }
    }
    
    // decoding
    
    func next() -> Element {
        store.next()
    }
    
    // misc
    
    var debugDescription: String {
        return "PrekeyedSingleElementStore(key: \(key), store:\(store.debugDescription))"
    }
}

struct RecursiveSingleElementStore: SingleElementStore {
    var _element: Element?
    
    let store: ContainerStore
    
    private var selfCopy: Self {
        get {
            guard let single = store.single else {
                store.single = self
                return self
            }
            
            return single as! Self
        }
        nonmutating set {
            store.single = newValue
        }
    }
    
    // encoding
    
    var element: Element? {
        get {
            selfCopy._element
        }
        nonmutating set {
            var copy = selfCopy
            copy._element = newValue
            selfCopy = copy
        }
    }
    
    // decoding
    
    func next() -> Element {
        _element!
    }
    
    // misc
    
    var debugDescription: String {
        guard let element = _element else {
            return "RecursiveSingleElementStore(nil)"
        }

        return "RecursiveSingleElementStore(\(element.debugDescription))"
    }
}



struct RecursiveKeyedElementStore<Key: CodingKey>: KeyedElementStore {
    var _elements: [(Key, Element?)]
    var _next: ThreadSpecificVariable<Box<Int>> = ThreadSpecificVariable()
    
    var thisNext: Int {
        get {
            if let next = _next.currentValue {
                return next.value
            } else {
                _next.currentValue = Box(0)
                return 0
            }
        }
        nonmutating set {
            if let next = _next.currentValue {
                next.value = newValue
            } else {
                _next.currentValue = Box(newValue)
            }
        }
    }
    
    let store: ContainerStore
    
    private var selfCopy: Self {
        get {
            guard let keyed = store.keyed else {
                store.keyed = self
                return self
            }
            
            return keyed as! Self
        }
        nonmutating set {
            store.keyed = newValue
        }
    }
    
    // encoding
    
    func add<K>(_ key: K) where K : CodingKey {
        guard let typedKey = key as? Key else {
            fatalError()
        }
        
        var copy = selfCopy
        copy._elements.append((typedKey, nil))
        selfCopy = copy
    }
    
    var current: Element? {
        get {
            let selfCopy = selfCopy
            
            guard selfCopy._elements.count > 0 else {
                return nil
            }
            
            return selfCopy._elements[selfCopy._elements.count - 1].1
        }
        nonmutating set {
            var copy = selfCopy
            
            guard copy._elements.count > 0 else {
                fatalError()
            }
            
            copy._elements[copy._elements.count - 1].1 = newValue
            selfCopy = copy
        }
    }
    
    // decoding
    
    func next() -> Element {
        let element = _elements[thisNext]
        
        thisNext = (thisNext + 1) % _elements.count
        
        return element.1!
    }
    
    
    // misc
    
    var debugDescription: String {
        return """
            RecursiveKeyedElementStore(
                \(_elements)
            )
        """
    }
}


// MARK: Coder


struct Coder: InstanceCoder {
    var codingPath: [CodingKey]
    
    var userInfo: [CodingUserInfoKey : Any]
    
    var store: ContainerStore
    
    let baseStore: BaseContainerStore
    
    init() {
        let store = BaseContainerStore()
        self.baseStore = store
        self.store = store
        self.codingPath = []
        self.userInfo = [:]
    }
    
    // encoding
    
    func singleInstanceEncodingContainer() throws -> SingleValueInstanceEncodingContainer {
        let nestedStore = RecursiveSingleElementStore(_element: nil, store: store)
        store.single = nestedStore
        return InstanceContainer(codingPath: self.codingPath, store: nestedStore)
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let nestedStore = RecursiveKeyedElementStore<Key>(_elements: [], store: store)
        store.keyed = nestedStore
        return KeyedEncodingContainer(KeyedInstanceEncodingContainer(codingPath: self.codingPath,
                                                                     encoder: self,
                                                                     store: nestedStore))
    }
    
    
    // decoding
    
    func singleInstanceDecodingContainer() throws -> SingleValueInstanceDecodingContainer {
        guard let nestedStore = store.next() as? SingleElementStore else {
            fatalError()
        }
        return InstanceContainer(codingPath: self.codingPath, store: nestedStore)
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let nestedStore = store.next() as? KeyedElementStore else {
            fatalError()
        }
        return KeyedDecodingContainer(KeyedInstanceDecodingContainer(codingPath: self.codingPath,
                                                                     decoder: self,
                                                                     store: nestedStore))
    }
    
    
    // fatals
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError()
    }
    
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
    
    let encoder: Coder
    
    let store: KeyedElementStore
    
    mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        if T.self is InstanceCodable.Type {
            store.add(key)
            store.current = .value(value)
            return
        }
        
        assert(value is DynamicProperty || value is Properties || value is Properties.EncodingWrapper,
               "You can only use 'Property's or 'DynamicProperty's on 'Handler's or values you pass into a 'Delegate'!")
        
        var encoder = encoder
        encoder.store = RecursiveContainerStore(_container: nil,
                                                store: PrekeyedSingleElementStore(store: self.store, key: key))
        encoder.codingPath += [key]
        
        try value.encode(to: encoder)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let nestedStore = RecursiveKeyedElementStore<NestedKey>(
            _elements: [],
            store: RecursiveContainerStore(_container: nil,
                                           store: PrekeyedSingleElementStore(store: self.store, key: key)))
        
        return KeyedEncodingContainer(KeyedInstanceEncodingContainer<NestedKey>(codingPath: self.codingPath + [key],
                                                                                encoder: self.encoder,
                                                                                store: nestedStore))
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
    
    let decoder: Coder
    
    let store: KeyedElementStore
    
    // decoding
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        if T.self is InstanceCodable.Type {
            guard case let .value(value) = store.next() else {
                fatalError()
            }
            return value as! T
        }
        
        var decoder = decoder
        guard case let .store(store) = store.next() else {
            fatalError()
        }
        decoder.store = store
        decoder.codingPath += [key]
        
        return try type.init(from: decoder)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        guard case let .store(containerStore) = store.next() else {
            fatalError()
        }
        
        guard let nestedStore = (containerStore as! RecursiveContainerStore).next() as? KeyedElementStore else {
            fatalError()
        }
        
        return KeyedDecodingContainer(KeyedInstanceDecodingContainer<NestedKey>(codingPath: self.codingPath + [key],
                                                                                decoder: self.decoder,
                                                                                store: nestedStore))
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

struct InstanceContainer: SingleValueInstanceEncodingContainer, SingleValueInstanceDecodingContainer {
    var codingPath: [CodingKey]
    
    let store: SingleElementStore
    
    var instance: Any {
        get {
            guard case let .value(instance) = store.element else {
                fatalError()
            }
            return instance
        }
        nonmutating set {
            store.element = .value(newValue)
        }
    }
    
    // encoding
    
    mutating func encode<T>(_ value: T) throws {
        guard T.self is InstanceCodable.Type else {
            fatalError()
        }
        
        instance = value
    }
    
    // decoding
    
    func decode<T>(_ type: T.Type) throws -> T {
        guard case let .value(value) = store.next() else {
            fatalError()
        }
        
        return value as! T
    }
    
    // fatals
    
    mutating func encodeNil() throws {
        fatalError()
    }
    
    func decodeNil() -> Bool {
        fatalError()
    }
}


// MARK: Default Conformance

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


// MARK: Properties Conformance

extension Properties: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PropertiesElements.self)
        
        let info = try container.decode(PropertiesCodableInformation.self, forKey: .codingInfo)
        
        let instanceContainer = try container.nestedContainer(keyedBy: String.self, forKey: .instances)
        
        var elements = [String: Property]()
        
        for (key, (type, _)) in info.codingInfo {
            let decoder = try instanceContainer.decode(DecoderExtractor.self, forKey: key).decoder
            elements[key] = try type.init(from: decoder) as! Property
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
    
    private struct PropertiesCodableInformation: InstanceCodable {
        let codingInfo: [String: (Decodable.Type, (Encoder, Property) throws -> Void)]
        let namingStrategy: ([String]) -> String?
    }
    
    private enum PropertiesElements: CodingKey {
        case instances
        case codingInfo
    }
}



// MARK: Mutator

//private protocol InstanceCoderStorage {
//    var single: InstanceContainer.Value { get nonmutating set }
//
//    func setKeyed<K: CodingKey>(_ value: KeyedInstanceContainer<K>.Value)
//
//    func getKeyed<K: CodingKey>(_ type: K.Type) -> KeyedInstanceContainer<K>.Value
//
//    var count: Int { get nonmutating set }
//
//    func append(_ value: Any)
//}
//
//private class BaseStorage: InstanceCoderStorage {
//    private var store: [Any] = []
//
//    var count: Int = -1
//
//    fileprivate var single: InstanceContainer.Value {
//        get {
//            store[count == -1 ? store.count - 1 : count] as! InstanceContainer.Value
//        }
//        set {
//            store[store.count - 1] = newValue as Any
//        }
//    }
//
//    fileprivate func getKeyed<K: CodingKey>(_ type: K.Type) -> KeyedInstanceContainer<K>.Value {
//        store[count == -1 ? store.count - 1 : count] as! KeyedInstanceContainer<K>.Value
//    }
//
//    fileprivate func setKeyed<K: CodingKey>(_ value: KeyedInstanceContainer<K>.Value) {
//        store[store.count - 1] = value
//    }
//
//    func append(_ value: Any) {
//        store.append(value)
//    }
//}
//
//struct Mutator: InstanceCoder {
//    var codingPath: [CodingKey] = [] // implementing that could become the real struggle
//
//    var userInfo: [CodingUserInfoKey : Any] = [:]
//
//    private let baseStorage: BaseStorage
//
//    fileprivate var store: InstanceCoderStorage
//
//    init() {
//        let storage = BaseStorage()
//        self.baseStorage = storage
//        self.store = storage
//    }
//
//    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
//        store.append(KeyedInstanceContainer<Key>.Value(count: -1, array: []))
//        return KeyedEncodingContainer(KeyedInstanceContainer(codingPath: self.codingPath, store: self.store, coder: self))
//    }
//
//    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
//        store.count += 1
//        return KeyedDecodingContainer(KeyedInstanceContainer(codingPath: self.codingPath, store: self.store, coder: self))
//    }
//
//    func singleInstanceEncodingContainer() throws -> SingleValueInstanceEncodingContainer {
//        store.append(InstanceContainer.Value.none as Any)
//        return InstanceContainer(store: self.store, codingPath: self.codingPath)
//    }
//
//    func singleInstanceDecodingContainer() throws -> SingleValueInstanceDecodingContainer {
//        store.count += 1
//        return InstanceContainer(store: self.store, codingPath: self.codingPath)
//    }
//
//    func unkeyedContainer() -> UnkeyedEncodingContainer {
//        fatalError() // UnkeyedInstanceEncodingContainer(injector: self)
//    }
//
//    func singleValueContainer() -> SingleValueEncodingContainer {
//        fatalError() // think that won't be needed InstanceContainer(injector: self)
//    }
//
//    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
//        fatalError() // UnkeyedInstanceDecodingContainer(injector: self)
//    }
//
//    func singleValueContainer() throws -> SingleValueDecodingContainer {
//        fatalError() // think that won't be needed InstanceContainer(injector: self)
//    }
//
//    mutating func reset() {
//        store = baseStorage
//        store.count = 0
//    }
//}
//
//// MARK: KeyedInstanceContainer
//
//private struct KeyedInstanceContainer<K: CodingKey>: KeyedEncodingContainerProtocol, KeyedDecodingContainerProtocol, InstanceCoderStorage {
//    enum Element {
//        case value(InstanceCodable?)
//        case container(Any)
//    }
//
//    typealias Key = K
//
//    typealias Value = (count: Int, array: [(key: K, value: Element)])
//
//    var codingPath: [CodingKey]
//
//    let store: InstanceCoderStorage
//
//    let coder: Mutator
//
//    var instances: [(key: K, value: Element)] {
//        get {
//            store.getKeyed(K.self).array
//        }
//        nonmutating set {
//            store.setKeyed((store.getKeyed(K.self).count, newValue))
//        }
//    }
//
//
//    var count: Int {
//        get {
//            store.getKeyed(K.self).count
//        }
//        nonmutating set {
//            store.setKeyed((newValue, store.getKeyed(K.self).array))
//        }
//    }
//
//    var single: InstanceContainer.Value {
//        get {
//            guard case let .container(container) = instances[count == -1 ? instances.count - 1 : count].value else {
//                fatalError()
//            }
//            return container as! InstanceContainer.Value
//        }
//        nonmutating set {
//            instances[instances.count - 1] = (instances[instances.count - 1].key, .container(newValue as Any))
//        }
//    }
//
//    func getKeyed<K: CodingKey>(_ type: K.Type) -> KeyedInstanceContainer<K>.Value {
//        guard case let .container(container) = instances[count == -1 ? instances.count - 1 : count].value else {
//            fatalError()
//        }
//        return container as! KeyedInstanceContainer<K>.Value
//    }
//
//    func setKeyed<K: CodingKey>(_ value: KeyedInstanceContainer<K>.Value) {
//        instances[instances.count - 1] = (instances[instances.count - 1].key, .container(value as Any))
//    }
//
//    func append(_ value: Any) {
//        instances.append(value as! (K, KeyedInstanceContainer<K>.Element))
//    }
//
//
//    var allKeys: [K] {
//        instances.map(\.key)
//    }
//
//    func contains(_ key: K) -> Bool {
//        instances.contains(where: { (instanceKey, _) in
//            key.stringValue == instanceKey.stringValue
//        })
//    }
//
//    mutating func encodeNil(forKey key: K) throws {
//        instances.append((key, .value(nil)))
//    }
//
//    func decodeNil(forKey key: K) throws -> Bool {
//        count += 1
//        guard case let (foundKey, .value(value)) = instances[count], key.stringValue == foundKey.stringValue else {
//            fatalError()
//        }
//        return value == nil
//    }
//
//    mutating func encode<T>(_ value: T, forKey key: K) throws {
//        if let dynamicProperty = value as? DynamicProperty {
//            var encoder = coder
//            encoder.store = self
//            try dynamicProperty.encode(to: encoder)
//        }
//
//        instances.append((key, .value((value as! InstanceCodable))))
//    }
//
//    func decode<T>(_ type: T.Type, forKey key: K) throws -> T {
//        count += 1
//
//        if let dynamicPropertyType = T.self as? DynamicProperty.Type {
//            var decoder = coder
//            decoder.store = self
//            return try dynamicPropertyType.init(from: decoder) as! T
//        }
//
//        guard case let (foundKey, .value(.some(value))) = instances[count], key.stringValue == foundKey.stringValue else {
//            fatalError()
//        }
//        return value as! T
//    }
//
//    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
//        instances.append((key, .container(KeyedInstanceContainer<NestedKey>.Value(count: -1, array: []))))
//        return KeyedEncodingContainer(KeyedInstanceContainer<NestedKey>(codingPath: self.codingPath + [key], store: self, coder: self.coder))
//    }
//
//    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
//        count += 1
//        return KeyedDecodingContainer(KeyedInstanceContainer<NestedKey>(codingPath: self.codingPath + [key], store: self, coder: self.coder))
//    }
//
//    mutating func superEncoder() -> Encoder {
//        fatalError()
//    }
//
//    mutating func superEncoder(forKey key: K) -> Encoder {
//        fatalError()
//    }
//
//    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
//        fatalError()
//    }
//
//    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
//        fatalError()
//    }
//
//    func superDecoder() throws -> Decoder {
//        fatalError()
//    }
//
//    func superDecoder(forKey key: K) throws -> Decoder {
//        fatalError()
//    }
//}
//
//// MARK: InstanceContainer
//
//private struct InstanceContainer: SingleValueInstanceDecodingContainer, SingleValueInstanceEncodingContainer {
//    typealias Value = InstanceCodable?
//
//    let store: InstanceCoderStorage
//
//    var instance: Value {
//        get {
//            store.single
//        }
//        nonmutating set {
//            store.single = newValue
//        }
//    }
//
//    var codingPath: [CodingKey]
//
//    func decode<T>(_ type: T.Type) throws -> T {
//        guard let typed = instance as? T else {
//            throw InstanceCodingError.badType
//        }
//
//        return typed
//    }
//
//    mutating func encode<T>(_ value: T) throws {
//        guard let typed = value as? InstanceCodable else {
//            throw InstanceCodingError.notImplemented
//        }
//
//        instance = typed
//    }
//
//    func decodeNil() -> Bool {
//        instance == nil
//    }
//
//    mutating func encodeNil() throws {
//        instance = nil
//    }
//}

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
