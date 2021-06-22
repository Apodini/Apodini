//
// Created by Andreas Bauer on 22.01.21.
//

import Apodini
import Vapor

extension REST {
    /// Configuration of the RESTful Interface
    public struct Configuration {
        let configuration: HTTPServer.Configuration
        let bindAddress: Vapor.BindAddress
        let uriPrefix: String

        init(_ configuration: HTTPServer.Configuration) {
            self.configuration = configuration
            self.bindAddress = configuration.address

            switch bindAddress {
            case .hostname:
                let httpProtocol: String
                var port = ""

                if configuration.tlsConfiguration == nil {
                    httpProtocol = "http://"
                    if configuration.port != 80 {
                        port = ":\(configuration.port)"
                    }
                } else {
                    httpProtocol = "https://"
                    if configuration.port != 443 {
                        port = ":\(configuration.port)"
                    }
                }

                self.uriPrefix = httpProtocol + configuration.hostname + port
            case let .unixDomainSocket(path):
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
