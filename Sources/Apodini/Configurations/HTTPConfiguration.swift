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
/// HTTPConfiguration(bindAddress: .hostname(port: 443), tlsFilePaths: TLSFilePaths(certificatePath: "/some/path/cert.pem", keyPath: "/some/path/key.pem"))
/// HTTPConfiguration(bindAddress: .address("localhost:8080"))
/// ```
public final class HTTPConfiguration: Configuration {
    /// Default values for bindAddress
    public enum Defaults {
        public static let hostname = "localhost"
        public static let port = 80
    }
    
    enum HTTPConfigurationError: LocalizedError {
        case incompatibleFlags

        var errorDescription: String? {
            switch self {
            case .incompatibleFlags:
                return "The command line arguments for HTTPConfiguration are invalid."
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .incompatibleFlags:
                return "Example usage of HTTPConfiguration: --hostname 0.0.0.0 --port 8080 or --bind 0.0.0.0:8080"
            }
        }
    }
    
    public var bindAddress: BindAddress
    public var supportVersions: Set<HTTPVersionMajor> = [.one]
    public var tlsConfiguration: TLSConfiguration?
    private var tlsUnsuccessful: Bool = false
    
    /// initalize HTTPConfiguration
    public init(bindAddress: BindAddress? = nil, tlsFilePaths: TLSFilePaths? = nil) {
        self.bindAddress = bindAddress ?? .hostname(Defaults.hostname, port: Defaults.port)
        
        do {
            if let paths = tlsFilePaths {
                let certificates = try NIOSSLCertificate.fromPEMFile(paths.certificatePath)
                let privateKey = try NIOSSLPrivateKey(file: paths.keyPath, format: .pem)
                
                self.supportVersions.insert(.two)
                self.tlsConfiguration = .makeServerConfiguration(
                    certificateChain: certificates.map { .certificate($0) },
                    privateKey: .privateKey(privateKey)
                )
            }
        } catch {
            self.tlsUnsuccessful = true
        }
    }

    /// Configure application
    public func configure(_ app: Application) {
        if supportVersions.contains(.two) {
            app.logger.info("Using HTTP/2 and TLS.")
        } else if tlsUnsuccessful {
            app.logger.warning("Error while enabling HTTP/2. Starting without HTTP/2.")
        } else {
            app.logger.info("No TLSFilePaths path provided. Starting without HTTP/2.")
        }
        
        app.storage[HTTPConfigurationStorageKey.self] = self
    }
}
