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

/// The ``InformationClass`` identifying any ``Information`` which holds Logging Metadata information.
public protocol LoggingMetadataInformationClass: StringKeyedCodableInformationClass {}

extension LoggingMetadataInformation: LoggingMetadataInformationClass {}

public extension LoggingMetadataInformationClass where Self == LoggingMetadataInformation {
    /// Returns the Logging Metadata as a tuple.
    var entry: (key: String, value: Codable) {
        (key: self.key.key, value: self.value)
    }
}

/// The `LoggingMetadataKey` identifying any `LoggingMetadataInformation` instances.
public struct LoggingMetadataKey: InformationKey {
    public typealias RawValue = Logger.MetadataValue

    public var key: String

    public init(_ key: String) {
        self.key = key
    }
}




/// An untyped `Information` instance holding some untyped HTTP header value.
/// You may use the `AnyHTTPInformation.typed(...)` method with a `HTTPInformation` type, to retrieve
/// a typed (and potentially parsed) version of the HTTP Header Information.
public struct LoggingMetadataInformation: Information {
    public let key: LoggingMetadataKey
    public let value: Logger.MetadataValue
    
    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        return encoder
    }()
    
    public init(key: LoggingMetadataKey, rawValue: Logger.MetadataValue) {
        self.key = key
        self.value = rawValue
    }
    
    public init(key: LoggingMetadataKey, stringValue: String) {
        self.init(key: key, rawValue: .string(stringValue))
    }
    
    /*
    public init(key: LoggingMetadataKey, metadataValue: Logger.MetadataValue) {
        self.init(key: key, rawValue: metadataValue)
        
        /*
        if let dataValue = try? Self.jsonEncoder.encode(metadataValue) {
            let stringValue = String(decoding: dataValue, as: UTF8.self)
            self.value = stringValue
        } else {
            self.value = "Unable to convert Logger.MetadataValue to string"
        }
         */
        
        //self.metadataValue = metadataValue
    }
     */
}


/// A `HTTPInformation` is a `DynamicInformationInstantiatable` for the `AnyHTTPInformation` `Information`.
/// It is used to provide implementations for individual HTTP Header types.
/// Currently the following Headers are supported as Information out of the box:
/// - `Authorization`
/// - `Cookies`
/// - `ETag`
/// - `Expires`
/// - `RedirectTo`
/*
public protocol LoggingMetadataInformation: InformationInstantiatable {
    typealias AssociatedInformation = AnyLoggingMetadataInformation

    /// The HTTP header type. Must to adhere to the according standard.
    //static var header: String { get }
}

public extension LoggingMetadataInformation {
    /// Default implementation automatically creating `InformationKey` using the
    /// `SomeHTTPInformation.header` property
    static var key: LoggingMetadataHeaderKey {
        LoggingMetadataHeaderKey(key.key)
    }
}

*/

/*
public extension LoggingMetadataInformation {
    /// Default implementation automatically creating `InformationKey` using the
    /// `SomeHTTPInformation.header` property
    static var key: LoggingMetadataHeaderKey {
        LoggingMetadataHeaderKey(header)
    }
}
 */

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
