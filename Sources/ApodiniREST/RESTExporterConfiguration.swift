//
// Created by Andreas Bauer on 22.01.21.
//

import Apodini
import Vapor

struct RESTConfiguration {
    let configuration: HTTPServer.Configuration
    let bindAddress: Vapor.BindAddress
    let uriPrefix: String
    let exporterConfiguration: REST.ExporterConfiguration

    init(_ configuration: HTTPServer.Configuration, exporterConfiguration: REST.ExporterConfiguration) {
        self.configuration = configuration
        self.bindAddress = configuration.address
        self.exporterConfiguration = exporterConfiguration

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

extension REST {
    /// Configuration of the `RESTInterfaceExporter`
    public struct ExporterConfiguration {
        /// The to be used `AnyEncoder` for encoding responses of the `RESTInterfaceExporter`
        public let encoder: AnyEncoder
        /// The to be used `AnyDecoder` for decoding requests to the `RESTInterfaceExporter`
        public let decoder: AnyDecoder
        
        /**
         Initializes the `RESTExporterConfiguration` of the `RESTInterfaceExporter`
         - Parameters:
             - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
             - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
         */
        public init(encoder: AnyEncoder = REST.defaultEncoder,
                    decoder: AnyDecoder = REST.defaultDecoder) {
            self.encoder = encoder
            self.decoder = decoder
        }
    }
}
