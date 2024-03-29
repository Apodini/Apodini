//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini

/// The ``InformationClass`` identifying any ``Information`` which holds HTTP Header information.
public protocol HTTPHeaderInformationClass: StringKeyedStringInformationClass {}

extension AnyHTTPInformation: HTTPHeaderInformationClass {}

public extension HTTPHeaderInformationClass where Self == AnyHTTPInformation {
    /// Returns the HTTP header as a tuple.
    var entry: (key: String, value: String) {
        (key: self.key.key, value: self.value)
    }
}

/// The `DynamicInformationKey` identifying any `AnyHTTPInformation` instances.
public struct HTTPHeaderKey: InformationKey {
    public typealias RawValue = String

    public var key: String

    public init(_ key: String) {
        self.key = key.lowercased()
    }
}
