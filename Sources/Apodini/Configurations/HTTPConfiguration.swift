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
    
    
    public var bindAddress: BindAddress
    public var hostname: Hostname
    public var supportVersions: Set<HTTPVersionMajor> = [.one]
    public var tlsConfiguration: TLSConfiguration?
    
    
    public var uriPrefix: String {
            let httpProtocol: String
            var port = ""
            
            if self.tlsConfiguration == nil {
                httpProtocol = "http://"
                if hostname.port != 80 {
                    port = ":\(hostname.port)"
                }
            } else {
                httpProtocol = "https://"
                if hostname.port != 443 {
                    port = ":\(hostname.port)"
                }
            }
            
        return httpProtocol + hostname.address + port
    }
    
    
    /// initalize HTTPConfiguration
    public init(hostname: Hostname? = nil, bindAddress: BindAddress? = nil, tlsConfigurationBuilder: TLSConfigurationBuilder? = nil) {
        var defaultPort = Defaults.httpPort
        
        if let tlsConfigBuilder = tlsConfigurationBuilder {
            self.supportVersions.insert(.two)
            self.tlsConfiguration = tlsConfigBuilder.tlsConfiguration
            defaultPort = Defaults.httpsPort
        }
        
        if let bindAddress = bindAddress {
            switch bindAddress {
            case let .interface(address, port):
                if port != nil {
                    self.bindAddress = bindAddress
                } else {
                    self.bindAddress = .interface(address, port: defaultPort)
                }
            case .unixDomainSocket:
                self.bindAddress = bindAddress
            }
        } else {
            self.bindAddress = .interface(Defaults.bindAddress, port: defaultPort)
        }

        if let hostname = hostname {
            if hostname.port == nil {
                self.hostname = Hostname(address: hostname.address, port: defaultPort)
            } else {
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
            app.logger.info("Starting without HTTP/2. and TLS")
        }
        
        app.storage[HTTPConfigurationStorageKey.self] = self
    }
}
