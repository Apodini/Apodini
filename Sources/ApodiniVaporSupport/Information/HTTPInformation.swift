//
// Created by Andreas Bauer on 03.07.21.
//

import Apodini

/// A `HTTPInformation` is a `DynamicInformationInstantiatable` for the `AnyHTTPInformation` `Information`.
/// It is used to provide implementations for individual HTTP Header types.
/// Currently the following Headers are supported as Information out of the box:
/// - `Authorization`
/// - `Cookies`
/// - `ETag`
/// - `Expires`
/// - `RedirectTo`
public protocol HTTPInformation: InformationInstantiatable {
    typealias AssociatedInformation = AnyHTTPInformation

    /// The HTTP header type. Must to adhere to the according standard.
    static var header: String { get }
}

public extension HTTPInformation {
    /// Default implementation automatically creating `InformationKey` using the
    /// `SomeHTTPInformation.header` property
    static var key: HTTPHeaderKey {
        HTTPHeaderKey(header)
    }
}


/// An untyped `Information` instance holding some untyped HTTP header value.
/// You may use the `AnyHTTPInformation.typed(...)` method with a `HTTPInformation` type, to retrieve
/// a typed (and potentially parsed) version of the HTTP Header Information.
public struct AnyHTTPInformation: Information {
    public let key: HTTPHeaderKey
    public let value: String

    public var header: String {
        key.key
    }

    /// Instantiates a new `AnyHTTPInformation` instance for the given HTTP key and value.
    /// - Parameters:
    ///   - key: The `HTTPInformationKey`.
    ///   - value: The raw string based HTTP Header value.
    public init(key: HTTPHeaderKey, rawValue: String) {
        self.key = key
        self.value = rawValue
    }
}
