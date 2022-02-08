//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniUtils
import ApodiniNetworking
import ApodiniHTTPProtocol


extension REST {
    /// Configuration of the `RESTInterfaceExporter`
    public struct ExporterConfiguration {
        /// The to be used `AnyEncoder` for encoding responses of the `RESTInterfaceExporter`
        public let encoder: AnyEncoder
        /// The to be used `AnyDecoder` for decoding requests to the `RESTInterfaceExporter`
        public let decoder: AnyDecoder
        /// How `Date` objects passed as query or path parameters should be decoded
        public let urlParamDateDecodingStrategy: DateDecodingStrategy
        /// Indicates whether the HTTP route is interpreted case-sensitively
        public let caseInsensitiveRouting: Bool
        /// Configures if the current web service version should be used as a prefix for all HTTP paths
        public let rootPath: RootPath?
        
        
        /// Initializes the `RESTExporterConfiguration` of the `RESTInterfaceExporter`
        /// - Parameters:
        ///    - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
        ///    - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
        ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitively
        ///    - rootPath: The ``RootPath`` under which the web service is registered.
        public init(
            encoder: AnyEncoder = REST.defaultEncoder,
            decoder: AnyDecoder = REST.defaultDecoder,
            urlParamDateDecodingStrategy: DateDecodingStrategy = .default,
            caseInsensitiveRouting: Bool = false,
            rootPath: RootPath? = nil
        ) {
            self.encoder = encoder
            self.decoder = decoder
            self.urlParamDateDecodingStrategy = urlParamDateDecodingStrategy
            self.caseInsensitiveRouting = caseInsensitiveRouting
            self.rootPath = rootPath
        }
    }
}
