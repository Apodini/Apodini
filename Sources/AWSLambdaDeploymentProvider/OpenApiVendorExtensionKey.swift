//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import OpenAPIKit


/// A strongly-typed key for setting and reading OpenAPI vendor extension values
public struct OpenAPIVendorExtensionKey<Value: Codable> {
    fileprivate let rawValue: String
    
    /// Creates a new key for a vendor extension, using `rawValue` as the key.
    /// The initializer will run a check to ensure the key has a `x-` prefix.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
        precondition(rawValue.hasPrefix("x-"), "OpenAPI vendor extensions must start with the 'x-' prefix")
    }
}


/// A collected key-value pair for an `OpenAPIVendorExtensionKey`
public struct CollectedVendorExtensionsKeyValuePair {
    let key: String
    let value: AnyCodable
    
    /// Creates a new `CollectedVendorExtensionsKeyValuePair`
    public init<T>(_ key: OpenAPIVendorExtensionKey<T>, _ value: T) {
        self.key = key.rawValue
        self.value = AnyCodable(value)
    }
}

extension Dictionary where Key == String, Value == AnyCodable {
    /// Creates a new dictionary from an array of collected vendor extension key-value pairs
    public init(vendorExtensions keyValuePairs: [CollectedVendorExtensionsKeyValuePair]) {
        self = .init(uniqueKeysWithValues: keyValuePairs.map { ($0.key, $0.value) })
    }
    
    /// Access the vendor extension value specified by the key
    public subscript<T>(key: OpenAPIVendorExtensionKey<T>) -> T? {
        get { self[key.rawValue]?.value as? T }
        set { self[key.rawValue] = newValue.map(AnyCodable.init) }
    }
}


extension Dictionary: ExpressibleByArrayLiteral where Key == String, Value == AnyCodable {
    public init(arrayLiteral elements: CollectedVendorExtensionsKeyValuePair...) {
        self.init(vendorExtensions: elements)
    }
}
