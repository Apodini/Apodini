//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import NIO
import NIOSSL

/// A `Configuration` for HTTP, HTTP/2 and TLS.
///
/// Examples of config via code:
/// ```
/// HTTPConfiguration(bindAddress: .interface(port: 443), tlsFilePaths: TLSFilePaths(certificatePath: "/some/path/cert.pem", keyPath: "/some/path/key.pem"))
/// HTTPConfiguration(bindAddress: .address("localhost:8080"))
/// ```
public final class HTTPConfiguration: Configuration {
    /// Default values for bindAddress
    public enum Defaults {
        public static let address = "localhost"
        public static let httpPort = 80
        public static let httpsPort = 443
        public static let bindAddress = "0.0.0.0"
    }
    
    
    /// The `BindAddress` that is used for bind the web service to a network interface
    public let bindAddress: BindAddress
    /// The `Hostname` that is used for populate information in exporters
    public let hostname: Hostname
    public let supportVersions: Set<HTTPVersionMajor>
    /// Information about the key and certificate needed to enable HTTPS.
    public let tlsConfiguration: TLSConfiguration?
    
    
    public var uriPrefix: String {
        let httpProtocol: String
        var port = ""
        if self.tlsConfiguration == nil {
            httpProtocol = "http://"
            if hostname.port != 80 {
                port = ":\(hostname.port!)"
            }
        } else {
            httpProtocol = "https://"
            if hostname.port != 443 {
                port = ":\(hostname.port!)"
            }
        }
        return httpProtocol + hostname.address + port
    }
    
    
    /// initalize HTTPConfiguration
    /// - Parameters:
    ///   - hostname: The `Hostname` that is used for populate information in exporters, the default value is `localhost:80` if there is no TLS configuration passed in the `HTTPConfiguration`, port 443 otherwise.
    ///   - bindAddress: The `BindAddress` that is used for bind the web service to a network interface, the default value is `0.0.0.0:80` if there is no TLS configuration passed in the `HTTPConfiguration`, port 443 otherwise.
    ///   - tlsConfigurationBuilder: Information about the key and certificate needed to enable HTTPS.
    public init(hostname: Hostname? = nil, bindAddress: BindAddress? = nil, tlsConfigurationBuilder: TLSConfigurationBuilder? = nil) {
        var defaultPort = Defaults.httpPort
        
        if let tlsConfigBuilder = tlsConfigurationBuilder {
            self.supportVersions = [.one, .two]
            self.tlsConfiguration = tlsConfigBuilder.tlsConfiguration
            defaultPort = Defaults.httpsPort
        } else {
            self.supportVersions = [.one]
            self.tlsConfiguration = nil
        }
        
        switch bindAddress {
        case let .interface(address, nil):
            self.bindAddress = .interface(address, port: defaultPort)
        case .interface:
            self.bindAddress = bindAddress!
        case .unixDomainSocket:
            self.bindAddress = bindAddress!
        default:
            self.bindAddress = .interface(Defaults.bindAddress, port: defaultPort)
        }

        if let hostname = hostname {
            switch (hostname.address, hostname.port) {
            case (_, nil):
                self.hostname = Hostname(address: hostname.address, port: defaultPort)
            default:
                self.hostname = hostname
            }
        } else {
            self.hostname = Hostname(address: Defaults.address, port: defaultPort)
        }
    }

    
    /// Configure application
    public func configure(_ app: Application) {
        if supportVersions.contains(.two) {
            app.logger.info("Using HTTP/2 and TLS.")
        } else {
            app.logger.info("Starting without HTTP/2 and TLS")
        }
        app.storage[HTTPConfigurationStorageKey.self] = self
    }
}
