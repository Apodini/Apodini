//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

import Apodini
import ApodiniUtils
import ApodiniNetworking
import ApodiniHTTPProtocol


/// Internal configuration of the `RESTInterfaceExporter` and `HTTPInterfaceExporter`
public struct HTTPExporterConfiguration {
    /// The to be used `AnyEncoder` for encoding responses of the exporter
    public let encoder: any AnyEncoder
    /// The to be used `AnyDecoder` for decoding requests to the exporter
    public let decoder: any AnyDecoder
    /// How `Date` objects passed as query or path parameters should be decoded
    public let urlParamDateDecodingStrategy: DateDecodingStrategy
    /// Indicates whether the HTTP route is interpreted case-sensitively
    public let caseInsensitiveRouting: Bool
    /// Configures if the current web service version should be used as a prefix for all HTTP paths
    public let rootPath: RootPath?
    /// Indicates whether exported routes should conform to REST.
    /// Mainly used to determine whether a response container should be used to wrap responses.
    public let exportAsREST: Bool
    
    
    /// Initializes the `HTTPExporterConfiguration` of the `InterfaceExporter`
    /// - Parameters:
    ///    - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
    ///    - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
    ///    - urlParamDateDecodingStrategy: The to be used `DateDecodingStrategy`
    ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitively
    ///    - rootPath: The ``RootPath`` under which the web service is registered.
    public init(
        encoder: any AnyEncoder = HTTP.defaultEncoder,
        decoder: any AnyDecoder = HTTP.defaultDecoder,
        urlParamDateDecodingStrategy: DateDecodingStrategy = .default,
        caseInsensitiveRouting: Bool = false,
        rootPath: RootPath? = nil,
        useResponseContainer: Bool = false
    ) {
        self.encoder = encoder
        self.decoder = decoder
        self.urlParamDateDecodingStrategy = urlParamDateDecodingStrategy
        self.caseInsensitiveRouting = caseInsensitiveRouting
        self.rootPath = rootPath
        self.exportAsREST = useResponseContainer
    }
}
