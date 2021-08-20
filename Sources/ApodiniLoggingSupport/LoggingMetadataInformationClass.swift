//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Logging

/// The ``InformationClass`` identifying any ``Information`` which holds Logging Metadata information.
public protocol LoggingMetadataInformationClass: StringKeyedEncodableInformationClass {}

extension LoggingMetadataInformation: LoggingMetadataInformationClass {}

public extension LoggingMetadataInformationClass where Self == LoggingMetadataInformation {
    /// Returns the Logging Metadata as a tuple.
    var entry: (key: String, value: Encodable) {
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

/// An `Information` instance holding logging metadata values.
public struct LoggingMetadataInformation: Information {
    public let key: LoggingMetadataKey
    public let value: Logger.MetadataValue
    
    public init(key: LoggingMetadataKey, rawValue: Logger.MetadataValue) {
        self.key = key
        self.value = rawValue
    }
    
    public init(key: LoggingMetadataKey, stringValue: String) {
        self.init(key: key, rawValue: .string(stringValue))
    }
}
