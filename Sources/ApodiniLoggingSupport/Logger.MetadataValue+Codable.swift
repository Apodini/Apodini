//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
import Logging

/// Make ``Logger.MetadataValue`` ``Encodable``
extension Logger.MetadataValue: Encodable {
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
}

/// IntermediateRepresentation to convert any ``Encodable`` data type to ``Logger.MetadataValue``
enum LoggerMetadataIntermediateRepresentation: Codable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([LoggerMetadataIntermediateRepresentation])
    case dictionary([String: LoggerMetadataIntermediateRepresentation])
    
    
    var metadataValue: Logger.MetadataValue {
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
            return .array(array.map({ $0.metadataValue }))
        case let .dictionary(dictionary):
            return .dictionary(dictionary.mapValues({ $0.metadataValue }))
        }
    }
    
    init(from decoder: Decoder) throws {
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
        } else if let array = try? container.decode([LoggerMetadataIntermediateRepresentation].self) {
            self = .array(array)
        } else if let dictionary = try? container.decode([String: LoggerMetadataIntermediateRepresentation].self) {
            self = .dictionary(dictionary)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Encountered unexpected JSON values")
            )
        }
    }
}

extension Logger.MetadataValue {
    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .deferredToData
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "+inf", negativeInfinity: "-inf", nan: "NaN")
        return encoder
    }()
    
    private static let jsonDecoder: JSONDecoder = {
        JSONDecoder()
    }()
    
    /// Converts a ``Codable`` element to ``Logger.MetadataValue``
    public static func convertToMetadata(encodableElement: Encodable) throws -> Logger.MetadataValue {
        let encodedElement = try encodableElement.encodeToJSON(outputFormatting: .withoutEscapingSlashes)
        return try Self.convertToMetadata(data: encodedElement)
    }
    
    /// Converts a ``Data`` element to ``Logger.MetadataValue``
    public static func convertToMetadata(data: Data) throws -> Logger.MetadataValue {
        try JSONDecoder().decode(LoggerMetadataIntermediateRepresentation.self, from: data).metadataValue
    }
    
    /// Converts ``Logger.MetadataValue`` to ``Data``
    public static func convertFromMetadata(_ metadata: Logger.MetadataValue) throws -> Data {
        try Self.jsonEncoder.encode(metadata)
    }
}
