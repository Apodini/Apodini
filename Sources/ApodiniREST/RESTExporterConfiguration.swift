//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import Vapor

extension REST {
    /// Configuration of the `RESTInterfaceExporter`
    public struct ExporterConfiguration {
        /// The to be used `AnyEncoder` for encoding responses of the `RESTInterfaceExporter`
        public let encoder: AnyEncoder
        /// The to be used `AnyDecoder` for decoding requests to the `RESTInterfaceExporter`
        public let decoder: AnyDecoder
        /// Indicates whether the HTTP route is interpreted case-sensitivly
        public let caseInsensitiveRouting: Bool
        
        
        /// Initializes the `RESTExporterConfiguration` of the `RESTInterfaceExporter`
        /// - Parameters:
        ///    - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
        ///    - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
        ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitivly
        public init(encoder: AnyEncoder = REST.defaultEncoder,
                    decoder: AnyDecoder = REST.defaultDecoder,
                    caseInsensitiveRouting: Bool = false) {
            self.encoder = encoder
            self.decoder = decoder
            self.caseInsensitiveRouting = caseInsensitiveRouting
        }
    }
}
