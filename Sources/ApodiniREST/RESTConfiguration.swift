//
// Created by Andreas Bauer on 22.01.21.
//

import Vapor

struct RESTConfiguration {
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
