//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//    

import Foundation
import Apodini
import Logging

public struct LoggingMetadataInformation: Information {
    private static var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        return encoder
    }
    
    public let key: LoggingMetadataKey
    public var value: String
    public let metadataValue: Logger.MetadataValue
    
    public var header: String {
        key.key
    }
    
    public init(key: LoggingMetadataKey, rawValue: String) {
        self.key = key
        self.value = rawValue
        self.metadataValue = .string(rawValue)
    }
    
    public init(key: LoggingMetadataKey, metadataValue: Logger.MetadataValue) {
        self.key = key
        
        if let dataValue = try? Self.jsonEncoder.encode(metadataValue) {
            let stringValue = String(decoding: dataValue, as: UTF8.self)
            self.value = stringValue
        } else {
            self.value = "Unable to convert Logger.MetadataValue to string"
        }
        
        self.metadataValue = metadataValue
    }
}

/// The `DynamicInformationKey` identifying any `LoggingMetadataInformation` instances.
public struct LoggingMetadataKey: InformationKey {
    public typealias RawValue = String

    public var key: String

    public init(_ key: String) {
        self.key = key
    }
}

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
