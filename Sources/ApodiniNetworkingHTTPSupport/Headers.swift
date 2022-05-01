//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
@_exported import NIOHTTP1
import NIOHTTP2
@_exported import NIOHPACK
import ApodiniUtils


/// A type which represents a HTTP header field value
public protocol HTTPHeaderFieldValueCodable: Hashable {
    /// Attempts to decode the string as a HTTP header value
    init?(httpHeaderFieldValue value: String)
    
    /// Encodes the receiver to a HTTP header value
    func encodeToHTTPHeaderFieldValue() -> String
}


/// A type which represents HTTP1 or HTTP2 headers
public protocol __ANNIOHTTPHeadersType {
    /// Initialises the headers type from a sequence of key-value pairs
    init(_ headers: [(String, String)])
    /// Checks whether at least one header entry exists for the specified key
    func contains(name: String) -> Bool
    /// Adds a header entry
    mutating func add(name: String, value: String, indexing: HPACKIndexing)
    /// Removes a header entry
    mutating func remove(name: String)
    /// Adds a header entry, removing any existing entries with the same key if necessary
    mutating func replaceOrAdd(name: String, value: String, indexing: HPACKIndexing)
    /// Fetches all values for the specified key 
    subscript(name: String) -> [String] { get }
    /// Fetches all key-value entries in this headers data structure
    var entries: [(String, String, HPACKIndexing)] { get } // swiftlint:disable:this large_tuple
}


extension NIOHPACK.HPACKHeaders: __ANNIOHTTPHeadersType {
    public var entries: [(String, String, HPACKIndexing)] { // swiftlint:disable:this large_tuple
        self.map { ($0.name, $0.value, $0.indexable) }
    }
}


extension NIOHTTP1.HTTPHeaders: __ANNIOHTTPHeadersType {
    public mutating func add(name: String, value: String, indexing: HPACKIndexing) {
        add(name: name, value: value)
    }
    
    public mutating func replaceOrAdd(name: String, value: String, indexing: HPACKIndexing) {
        replaceOrAdd(name: name, value: value)
    }
    
    public var entries: [(String, String, HPACKIndexing)] { // swiftlint:disable:this large_tuple
        self.map { ($0.name, $0.value, .indexable) }
    }
}


/// An untyped HTTP/1 or HTTP/2 header key.
public class AnyHTTPHeaderName: Equatable {
    public let rawValue: String
    internal init(_ value: String) {
        self.rawValue = value
    }
    
    public static func == (lhs: AnyHTTPHeaderName, rhs: AnyHTTPHeaderName) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}


/// A typed HTTP (1 or 2) header name, i.e. the key in a header field.
/// - Note: The standard differentiates between single-value and multi-value header fields
///         (i.e. headers which can have only one value, and also appear only once; and headers which can have multiple values and also may appear multiple times).
///         You can control whether a header name defined using this API is a single- or multi-value header by wrapping the header type in an `Array`.
///         For example: `let date = HeaderName<Date>("Date")` defines a single-value header (the Date header may only appear once, and can only contain one value).
///         On the other hand, `let contentEncoding = HeaderName<[HTTPContentEncoding]>("Content-Encoding")` would define a multi-value header, which can contain one or more values, and may also appear multiple times itself.
/// See also: https://datatracker.ietf.org/doc/html/rfc7230#section-3.2
public class HTTPHeaderName<T: HTTPHeaderFieldValueCodable>: AnyHTTPHeaderName {
    override public init(_ value: String) {
        super.init(value)
    }
}


extension __ANNIOHTTPHeadersType {
    /// Initialises a new empty headers struct
    public init() {
        self.init([])
    }
    
    /// Initialises a headers struct from the specified key-value pairs
    public init<S: Sequence>(_ elements: S) where S.Element == (String, String) {
        self.init(Array(elements))
    }
    
    /// Initialises a new headers struct with the specified entries
    public init<S: Sequence>(_ elements: S) where S.Element == (String, String, HPACKIndexing) { // swiftlint:disable:this large_tuple
        self.init()
        for (name, value, indexing) in elements {
            add(name: name, value: value, indexing: indexing)
        }
    }
    
    /// Creates a new headers struct, giving the caller the opportunity to initialise it via the closure.
    /// - Note: The reason this initialiser exists is to offer a type-safe way of declaring immutable headers objects.
    ///         The underlying problem here is that Swift doesn't support variadic generics, meaning that (since the type-safe header
    ///         names are implemented via generics) you wouldn't be able to pass more than one generic key-value pair to the initialiser.
    ///         This initialiser works around that by giving the caller the ability to access a mutable version of the headers
    ///         struct (which can be modified using the type-safe API), while still allowing the caller to store the resulting value into an immutable object.
    ///         Since the block is non-escaping, immediately evaluated, and evaluated only once, this is semantically equivalent to declaring a mutable headers object and modifying that.
    public init(_ block: (inout Self) throws -> Void) rethrows {
        self.init([])
        try block(&self)
    }
    
    /// Checks whether at least one entry exists for the specified name
    public func isPresent<T>(_ name: HTTPHeaderName<T>) -> Bool {
        self.contains(name: name.rawValue)
    }
    
    /// Sets the specified value for `name`, if no entry for that key already exists
    public mutating func setUnlessPresent<T: HTTPHeaderFieldValueCodable>(
        name: HTTPHeaderName<T>,
        value: @autoclosure () -> T,
        indexing: HPACKIndexing = .indexable
    ) {
        guard !self.contains(name: name.rawValue) else {
            return
        }
        self.add(name: name.rawValue, value: value().encodeToHTTPHeaderFieldValue(), indexing: indexing)
    }
    
    /// Removes all entries for the specified header name
    public mutating func remove<T>(_ name: HTTPHeaderName<T>) {
        remove(name: name.rawValue)
    }
    
    /// Access a single-value typed header field
    /// - Returns: When reading: `nil` if the field is not present
    /// - Throws: When reading: if the field is present, but there was an error decoding its value. When writing: if there was an error encoding the new value
    /// - Note: Using this subscript to set HTTP2 header values will default the HPACKIndexable property to .indexable. If you don't want this, use the `add` or `replaceOrAdd` functions
    public subscript<T: HTTPHeaderFieldValueCodable>(name: HTTPHeaderName<T>) -> T? {
        get {
            let values = self[name.rawValue]
            precondition(values.count < 2, "Unexpectedly retrieved two or more values for single-value header field '\(name.rawValue)'")
            return values.first.flatMap { T(httpHeaderFieldValue: $0) }
        }
        set {
            if let newValue = newValue {
                self.replaceOrAdd(name: name.rawValue, value: newValue.encodeToHTTPHeaderFieldValue(), indexing: .indexable)
            } else {
                self.remove(name: name.rawValue)
            }
        }
    }
    
    /// Access a multi-value typed header field
    /// - Returns: When reading: `nil` if the field is not present
    /// - Throws: When reading: if the field is present, but there was an error decoding its value. When writing: if there was an error encoding the new value
    /// - Note: Using this subscript to set HTTP2 header values will default the HPACKIndexable property to .indexable. If you don't want this, use the `add` or `replaceOrAdd` functions
    public subscript<T: HTTPHeaderFieldValueCodable>(name: HTTPHeaderName<[T]>) -> [T] {
        get {
            switch name {
            case .setCookie:
                // Set-Cookie requires special handling because we can't split or join its values in a comma separator
                return self[name.rawValue].map { T(httpHeaderFieldValue: $0)! }
            default:
                // All other headers can be split on commas
                return self[name.rawValue]
                    .flatMap { $0.split(separator: ",") }
                    .map { $0.trimmingLeadingWhitespace() }
                    .map { T(httpHeaderFieldValue: String($0))! }
            }
        }
        set {
            // We're overwriting an array of header fields, so we have to remove all previous entries for this name
            remove(name)
            guard !newValue.isEmpty else {
                return
            }
            switch name {
            case .setCookie:
                let encodedValues = newValue.map { $0.encodeToHTTPHeaderFieldValue() }
                for value in encodedValues {
                    add(name: name.rawValue, value: value, indexing: .indexable)
                }
            default:
                add(
                    name: name.rawValue,
                    value: newValue.map { $0.encodeToHTTPHeaderFieldValue() }.joined(separator: ", "),
                    indexing: .indexable
                )
            }
        }
    }
    
    /// Lowercases, in-place, all header names.
    public mutating func lowercaseAllHeaderNames() {
        self = withLowercasedHeaderNames()
    }
    
    /// Returns a copy of the struct where all header names are lowercased
    public func withLowercasedHeaderNames() -> Self {
        Self(entries.map { ($0.lowercased(), $1, $2) })
    }
    
    
    /// Makes, to this headers object, the modificatios required to ensure that they can be handed over to NIO to form a HTTP/2 HEADERS frame
    public mutating func applyHTTP2Validations() {
        self = applyingHTTP2Validations()
    }
    
    /// Returns a copy of this headers object, with HTTP/2 validations applied
    public func applyingHTTP2Validations() -> Self {
        var pseudoHeaderEntries: [(String, String, HPACKIndexing)] = []
        var nonPseudoHeaderEntries: [(String, String, HPACKIndexing)] = []
        for (headerName, headerValue, indexing) in entries {
            if headerName.hasPrefix(":") {
                pseudoHeaderEntries.append((headerName.lowercased(), headerValue, indexing))
            } else {
                nonPseudoHeaderEntries.append((headerName.lowercased(), headerValue, indexing))
            }
        }
        return Self(pseudoHeaderEntries.sorted(by: \.0).appending(contentsOf: nonPseudoHeaderEntries.sorted(by: \.0)))
    }
}
