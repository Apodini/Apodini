//
//  Storage.swift
//  
//
//  Created by Tim Gymnich on 22.12.20.
//
//
// This code is based on the Vapor project: https://github.com/vapor/vapor
//
// The MIT License (MIT)
//
// Copyright (c) 2020 Qutheory, LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import Logging


/// Enables swift extensions to declare "stored" properties for use in application configuration
public struct Storage {
    var storage: [ObjectIdentifier: AnyStorageValue]

    struct Value<T>: AnyStorageValue {
        var value: T
        var onShutdown: ((T) throws -> Void)?
        func shutdown(logger: Logger) {
            do {
                try self.onShutdown?(self.value)
            } catch {
                logger.error("Could not shutdown \(T.self): \(error)")
            }
        }
    }
    let logger: Logger

    /// Initialize application storage
    public init(logger: Logger = .init(label: "org.apodini.storage")) {
        self.storage = [:]
        self.logger = logger
    }

    /// Clear application storage
    public mutating func clear() {
        self.storage = [:]
    }

    /// Get element from application storage
    public subscript<Key: StorageKey>(_ key: Key.Type) -> Key.Value? {
        get {
            self.get(Key.self)
        }
        set {
            self.set(Key.self, to: newValue)
        }
    }
    
    /// Accesses the environment value associated with a custom key.
    public subscript<Key, Type>(_ keyPath: KeyPath<Key, Type>) -> Type? {
        get {
            self.get(keyPath)
        }
        set {
            self.set(keyPath, to: newValue)
        }
    }

    /// Check if application storage contains a certain key
    public func contains<Key>(_ key: Key.Type) -> Bool {
        self.storage.keys.contains(ObjectIdentifier(Key.self))
    }
    
    /// Check if application storage contains a certain key path
    public func contains<Key, Type>(_ keyPath: KeyPath<Key, Type>) -> Bool {
        self.storage.keys.contains(ObjectIdentifier(keyPath))
    }

    /// Get a a value for a key from application storage
    public func get<Key: StorageKey>(_ key: Key.Type) -> Key.Value? {
        guard let value = self.storage[ObjectIdentifier(Key.self)] as? Value<Key.Value> else {
            return nil
        }
        return value.value
    }
    
    /// Get a a value for a key path from application storage
    public func get<Key, Type>(_ keyPath: KeyPath<Key, Type>) -> Type? {
        guard let value = storage[ObjectIdentifier(keyPath)] as? Value<Type> else {
            return nil
        }
        return value.value
    }
    
    /// Get a a value for an `ObjectIdentifier` and a Type from application storage
    public func get<Element>(_ objectIdentifer: ObjectIdentifier, _ key: Element.Type) -> Element? {
        guard let value = storage[objectIdentifer] as? Value<Element> else {
            return nil
        }
        return value.value
    }

    /// Set a key for a value in application storage
    public mutating func set<Key: StorageKey>(
        _ key: Key.Type,
        to value: Key.Value?,
        onShutdown: ((Key.Value) throws -> Void)? = nil
    ) {
        let key = ObjectIdentifier(Key.self)
        if let value = value {
            self.storage[key] = Value(value: value, onShutdown: onShutdown)
        } else if let existing = self.storage[key] {
            self.storage[key] = nil
            existing.shutdown(logger: self.logger)
        }
    }
    
    /// Set a value for a key path in application storage
    public mutating func set<Key, Type>(_ keyPath: KeyPath<Key, Type>, to value: Type?) {
        if let value = value {
            self.storage[ObjectIdentifier(keyPath)] = Value(value: value, onShutdown: nil)
        } else {
            self.storage[ObjectIdentifier(keyPath)] = nil
        }
    }

    /// Handle shutdown in every stored configuration element
    public func shutdown() {
        self.storage.values.forEach {
            $0.shutdown(logger: self.logger)
        }
    }
}


protocol AnyStorageValue {
    func shutdown(logger: Logger)
}


/// Key used to identify stored elements in application storage.
public protocol StorageKey {
    /// value
    associatedtype Value
}
