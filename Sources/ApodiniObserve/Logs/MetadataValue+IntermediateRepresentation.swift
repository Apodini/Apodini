//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
// 

import Foundation
import Logging

/// Extends the ``Logger.MetadataValue`` struct of swift-log to allow for easy encoding of ``Codable`` object to ``Logger.MetadataValue``
public extension Logger.MetadataValue {
    /// An intermediate representation to encode every `Codable` object as a `Logger.Metadata` object
    enum IntermediateRepresentation: Codable {
        case null
        case bool(Bool)
        case int(Int)
        case double(Double)
        case string(String)
        case array([IntermediateRepresentation])
        case dictionary([String: IntermediateRepresentation])
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
             
            if container.decodeNil() {
                self = .null
            } else if let bool = try? container.decode(Bool.self) {
                self = .bool(bool)
            } else if let int = try? container.decode(Int.self) {
                self = .int(int)
            } else if let double = try? container.decode(Double.self) {
                self = .double(double)
            } else if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let array = try? container.decode([IntermediateRepresentation].self) {
                self = .array(array)
            } else if let dictionary = try? container.decode([String: IntermediateRepresentation].self) {
                self = .dictionary(dictionary)
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath,
                                          debugDescription: "Encountered unexpected JSON values")
                )
            }
        }
        
        /// A computed property to get the converted ``Logger.MetadataValue``
        var metadata: Logger.MetadataValue {
            switch self {
            case .null:
                return .string("null")
            case let .bool(bool):
                return .string("\(bool)")
            case let .int(int):
                return .string("\(int)")
            case let .double(double):
                return .string("\(double)")
            case let .string(string):
                return .string(string)
            case let .array(array):
                return .array(array.map({ $0.metadata }))
            case let .dictionary(dictionary):
                return .dictionary(dictionary.mapValues({ $0.metadata }))
            }
        }
    }
    
    
}

/*
/// Make `Logger.MetadataValue` conform to `Encodable` and `Decodable`, so it can be sent to Logstash
extension Logger.MetadataValue: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case let .string(string):
            try container.encode(string)
        case let .stringConvertible(stringConvertible):
            try container.encode(stringConvertible.description)
        case let .dictionary(dictionary):
            try container.encode(dictionary)
        case let .array(array):
            try container.encode(array)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .string("null")
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([Logger.MetadataValue].self) {
            self = .array(array)
        } else if let dictionary = try? container.decode(Logger.Metadata.self) {
            self = .dictionary(dictionary)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Encountered unexpected JSON values")
            )
        }
    }
}
 */
 
extension Logger.MetadataValue {
    /// Converts a ``Codable`` object to ``Logger.MetadataValue``
    static func convertToMetadata(parameter: Encodable) -> Logger.MetadataValue {
        do {
            let encodedParameter = try parameter.encodeToJSON()
            
            // If parameter is too large, cut if after 8kb
            if encodedParameter.count > 8_192 {
                return .string("\(encodedParameter.description.prefix(8_100))... (Further bytes omitted since parameter too large!)")
            }
            
            return try JSONDecoder().decode(Logger.MetadataValue.self, from: encodedParameter)
        } catch {
            return .string("Error during encoding of the parameter")
        }
    }
}

