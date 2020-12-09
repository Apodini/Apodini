//
//  Coder.swift
//  
//
//  Created by Tim Gymnich on 2.12.20.
//

import Foundation

/// A type that  decodes a top-level value of the given type from a given representation.
public protocol DecoderProtocol {
    /// Decodes a top-level value of the given type from a given representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid.
    /// - throws: An error if any value throws an error during decoding.
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

/// A type that encodes the given top-level value and returns its encoded representation.
public protocol EncoderProtocol {
    /// Encodes the given top-level value and returns its encoded representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension JSONDecoder: DecoderProtocol {}
extension JSONEncoder: EncoderProtocol {}

struct AnyEncodable: Encodable {

    private let encodable: Encodable

    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
