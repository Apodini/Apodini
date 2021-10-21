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


extension REST {
    /// Configuration of the RESTful Interface
    public struct Configuration { // TODO this is reduncant and can/should be removed, since all its used for seems to be passing the url prefix constructed in the initialiser somethere else via the IE
        let configuration: Apodini.Application.HTTP
//        let bindAddress: BindAddress
        let uriPrefix: String
        
        init(_ configuration: Apodini.Application.HTTP) {
            self.configuration = configuration
//            self.bindAddress = configuration.address!
            
            switch configuration.address {
            case .hostname(let hostname, let port):
                let hasTLS = configuration.tlsConfiguration != nil
                self.uriPrefix = "http\(hasTLS ? "s" : "")://\(hostname ?? HTTPConfiguration.Defaults.hostname):\(port ?? HTTPConfiguration.Defaults.port)"
//                let httpProtocol: String
//                var port = ""
//                
//                if configuration.tlsConfiguration == nil {
//                    httpProtocol = "http://"
//                    if configuration.port != 80 {
//                        port = ":\(configuration.port)"
//                    }
//                } else {
//                    httpProtocol = "https://"
//                    if configuration.port != 443 {
//                        port = ":\(configuration.port)"
//                    }
//                }
//                
//                self.uriPrefix = httpProtocol + configuration.hostname + port
            case .unixDomainSocket(let path):
                let httpProtocol: String
                
                if configuration.tlsConfiguration == nil {
                    httpProtocol = "http"
                } else {
                    httpProtocol = "https"
                }
                
                self.uriPrefix = httpProtocol + "+unix: " + path
            }
        }
    }
    
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
