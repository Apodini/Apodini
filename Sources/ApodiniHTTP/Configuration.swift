//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniExtension
import ApodiniHTTPProtocol
import ApodiniNetworking


extension HTTP {
    /// Configuration that can be used to customize the behavior of the ``HTTP`` exporter.
    public struct ExporterConfiguration {
        /// The `AnyEncoder` to be used for encoding responses
        public let encoder: AnyEncoder
        /// The `AnyDecoder` to be used for decoding requests
        public let decoder: AnyDecoder
        /// How `Date` objects passed as query or path parameters should be decoded.
        public let urlParamDateDecodingStrategy: DateDecodingStrategy
        /// Indicates whether the HTTP route is interpreted case-sensitivly
        public let caseInsensitiveRouting: Bool
        /// Configures the root path for the HTTP endpoints
        public let rootPath: RootPath?
        
        /// Initializes the configuration of the ``HTTP`` exporter
        /// - Parameters:
        ///    - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
        ///    - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
        ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitivly
        ///    - rootPath: Configures the root path for the HTTP endpoints
        public init(
            encoder: AnyEncoder = HTTP.defaultEncoder,
            decoder: AnyDecoder = HTTP.defaultDecoder,
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
