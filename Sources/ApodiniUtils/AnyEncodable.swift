//
//  AnyEncodable.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import Foundation
import Vapor

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
public protocol AnyEncoder: ContentEncoder {
    /// Encode some `Encodable` object to `Data`
    func encode<E: Encodable>(_ value: E) throws -> Data
}

/// Something that can decode `Decodable` objects to the given respective type
public protocol AnyDecoder: ContentDecoder {
    /// Decode some `Decodable` data to the given type
    func decode<D>(_ type: D.Type, from data: Data) throws -> D where D: Decodable
}

/// Default implementation of the `ContentEncoder` protocol that sets the content type to JSON
extension AnyEncoder {
    /**
     Encodes the given object which conform to `Encodable` into the `Bytebuffer`
     - Parameters:
        - encodable: The to be encoded object
        - to: The ByteBuffer to encode to
        - headers: The HTTP header to set the content type
     */
    public func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders) throws where E: Encodable {
        headers.contentType = .json
        try body.writeBytes(self.encode(encodable))
    }
}

/// Default implementation of the `ContentDecoder` protocol
extension AnyDecoder {
    /**
     Decodes the given object which conform to `Decodable` from the `Bytebuffer`
     - Parameters:
        - decodable: The type of the to be decoded object
        - to: The ByteBuffer to encode from
        - headers: The HTTP header to get the content type
     */
    public func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D where D: Decodable {
        let data = body.getData(at: body.readerIndex, length: body.readableBytes) ?? Data()
        return try self.decode(D.self, from: data)
    }
}

extension JSONEncoder: AnyEncoder {}

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
