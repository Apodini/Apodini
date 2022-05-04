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
/// HTTPConfiguration(bindAddress: .init(port: 443), tlsFilePaths: TLSFilePaths(certificatePath: "/some/path/cert.pem", keyPath: "/some/path/key.pem"))
/// HTTPConfiguration(bindAddress: .init("localhost:8080")!)
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
    /// Whether the configuration enables TLS.
    public var isTLSEnabled: Bool { tlsConfiguration != nil }
    
    public var uriPrefix: String {
        hostname.uriPrefix(isTLSEnabled: isTLSEnabled)
    }
    
    /// initialize HTTPConfiguration
    /// - Parameters:
    ///   - hostname: The `Hostname` that is used for populate information in exporters, the default value is `localhost:80` if there is no TLS configuration passed in the `HTTPConfiguration`, port 443 otherwise.
    ///   - bindAddress: The `BindAddress` that is used for bind the web service to a network interface, the default value is `0.0.0.0:80` if there is no TLS configuration passed in the `HTTPConfiguration`, port 443 otherwise.
    ///   - tlsConfiguration: Information about the key and certificate needed to enable HTTPS.
    public init(hostname: BindAddress, bindAddress: BindAddress, tlsConfiguration: TLSConfiguration? = nil) {
        self.hostname = hostname
        self.bindAddress = bindAddress
        if var tlsConfiguration = tlsConfiguration {
            tlsConfiguration.applicationProtocols.appendUnlessPresent("h2")
            tlsConfiguration.applicationProtocols.appendUnlessPresent("http/1.1")
            self.tlsConfiguration = tlsConfiguration
            self.supportVersions = [.one, .two]
        } else {
            self.tlsConfiguration = nil
            self.supportVersions = [.one]
        }
    }
    
    /// initialize HTTPConfiguration
    /// - Parameters:
    ///   - hostname: The `Hostname` that is used for populate information in exporters, the default value is `localhost:80` if there is no TLS configuration passed in the `HTTPConfiguration`, port 443 otherwise.
    ///   - bindAddress: The `BindAddress` that is used for bind the web service to a network interface, the default value is `0.0.0.0:80` if there is no TLS configuration passed in the `HTTPConfiguration`, port 443 otherwise.
    ///   - tlsConfiguration: Information about the key and certificate needed to enable HTTPS.
    public convenience init(
        hostname hostnameInput: BindAddressInput? = nil,
        bindAddress bindAddressInput: BindAddressInput? = nil,
        tlsConfiguration: TLSConfiguration? = nil
    ) {
        let bindAddress = BindAddress(
            address: bindAddressInput?.address ?? Defaults.bindAddress,
            port: bindAddressInput?.port ?? (tlsConfiguration == nil ? Defaults.httpPort : Defaults.httpsPort)
        )
        // We use the port from the bindAddress as the default port for the hostname, taking precedence over the default HTTP port.
        let hostname = Hostname(address: hostnameInput?.address ?? Defaults.address, port: hostnameInput?.port ?? bindAddress.port)
        self.init(hostname: hostname, bindAddress: bindAddress, tlsConfiguration: tlsConfiguration)
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
