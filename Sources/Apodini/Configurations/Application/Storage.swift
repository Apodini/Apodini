//
//  Storage.swift
//  
//
//  Created by Tim Gymnich on 22.12.20.
//

import Logging

/// Enables swift extensions to declare "storred" properties for use in application configuration
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

    /// Check if application storage contains a certain key
    public func contains<Key>(_ key: Key.Type) -> Bool {
        self.storage.keys.contains(ObjectIdentifier(Key.self))
    }

    /// Get a a value for a key from application storage
    public func get<Key: StorageKey>(_ key: Key.Type) -> Key.Value? {
        guard let value = self.storage[ObjectIdentifier(Key.self)] as? Value<Key.Value> else {
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
