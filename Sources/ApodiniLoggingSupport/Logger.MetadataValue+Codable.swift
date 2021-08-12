//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Logging

/// Make ``Logger.MetadataValue`` ``Codable``
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
        return try Self.jsonDecoder.decode(Logger.MetadataValue.self, from: data)
    }
    
    /// Converts ``Logger.MetadataValue`` to ``Data``
    public static func convertFromMetadata(_ metadata: Logger.MetadataValue) throws -> Data {
        try Self.jsonEncoder.encode(metadata)
    }
}
