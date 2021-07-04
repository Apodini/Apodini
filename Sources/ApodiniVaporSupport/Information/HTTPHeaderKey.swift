//
// Created by Andreas Bauer on 03.07.21.
//

import Apodini

/// The ``InformationClass`` identifying any ``Information`` which holds HTTP Header information.
public protocol HTTPHeaderInformationClass: InformationClass {
    var entry: (header: String, value: String) { get }
}

extension AnyHTTPInformation: HTTPHeaderInformationClass {}
public extension HTTPHeaderInformationClass where Self == AnyHTTPInformation {
    /// Returns the HTTP header as a tuple.
    var entry: (header: String, value: String) {
        (header: self.key.key, value: self.value)
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
