//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

/// A type-erasing wrapper around some `Encodable` value
public struct AnyEncodable: Encodable {
    public let wrappedValue: Encodable
    
    public init(_ wrappedValue: Encodable) {
        self.wrappedValue = wrappedValue
    }
    
    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension AnyEncodable {
    /// Fetch the `AnyEncodable`'s value, cast to a specific type
    public func typed<T: Encodable>(_ type: T.Type = T.self) -> T? {
        guard let anyEncodableWrappedValue = wrappedValue as? AnyEncodable else {
            return wrappedValue as? T
        }
        return anyEncodableWrappedValue.typed(T.self)
    }
}


/// Something that can encde `Encodable` objects to `Data`
public protocol AnyEncoder {
    /// Encode some `Encodable` object to `Data`
    func encode<E: Encodable>(_ value: E) throws -> Data
    
    /// The HTTP media type associated with the data format produced by this encoder.
    /// Return `nil` if not applicable
    var resultMediaTypeRawValue: String? { get }
}

extension JSONEncoder: AnyEncoder {
    public var resultMediaTypeRawValue: String? {
        "application/json; charset=utf-8"
    }
}


/// Something that can decode `Decodable` objects from `Data`
public protocol AnyDecoder {
    /// Decode some `Decodable` object from `Data`
    func decode<T>(_: T.Type, from: Data) throws -> T where T: Decodable
}

extension JSONDecoder: AnyDecoder {}


// MARK: Null

/// A `Codable`-conformant equivalent of `NSNull`
public struct Null: Codable {
    public init() {}
    
    public init(from decoder: Decoder) throws {
        guard try decoder.singleValueContainer().decodeNil() else {
            throw ApodiniUtilsError(message: "Expected nil value")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}


// MARK: Other

extension Encodable {
    /// Encode the object to JSON
    public func encodeToJSON(outputFormatting: JSONEncoder.OutputFormatting = []) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting
        return try encoder.encode(self)
    }
    
    /// Encode the object to JSON and write this JSON representation to the specified file
    public func writeJSON(
        to url: URL,
        encoderOutputFormatting: JSONEncoder.OutputFormatting = [.prettyPrinted],
        writingOptions: Data.WritingOptions = []
    ) throws {
        let data = try encodeToJSON(outputFormatting: encoderOutputFormatting)
        try data.write(to: url, options: writingOptions)
    }
}


extension Decodable {
    /// Initialise the value by decoding the specified data using the `JSONDecoder`
    public init(decodingJSON data: Data) throws {
        self = try JSONDecoder().decode(Self.self, from: data)
    }
    
    /// Initialise the value by decoding the contents of the file at the specified URL using the `JSONDecoder`
    public init(decodingJSONAt url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}


extension JSONEncoder {
    /// Creates a new `JSONEncoder`, with the specified output formatting options
    public convenience init(outputFormatting: JSONEncoder.OutputFormatting) {
        self.init()
        self.outputFormatting = outputFormatting
    }
}
