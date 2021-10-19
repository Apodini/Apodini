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
/// The configuration can be done in two ways, either via the
/// command line arguments --hostname, --port, --bind,  --cert and --key or via the
/// functions `address` `certificate` or `key`.
///
/// Example command line arguments:
/// --cert=/some/path/cert.pem
/// --key=/some/path/key.pem
///
/// Example of config via code:
/// ```
/// HTTPConfiguration()
///     .address(.hostname("localhost", port: 80))
///     .certificate("/some/path/cert.pem")
///     .key("/some/path/key.pem")
/// ```
public final class HTTPConfiguration: Configuration {
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
    private var certURL: URL?
    private var keyURL: URL?
    public var supportVersions: Set<HTTPVersionMajor> = [.one]
    public var tlsConfiguration: TLSConfiguration?
    
    /// initalize HTTPConfiguration
    public init(hostname: String? = nil, port: Int? = nil, bind: String? = nil, socketPath: String? = nil, cert: String? = nil, keyPath: String? = nil) {
        do {
            switch (hostname, port, bind, socketPath) {
            case (.none, .none, .none, .none):
                self.bindAddress = .hostname(Defaults.hostname, port: Defaults.port)
            case (.none, .none, .none, .some(let socketPath)):
                self.bindAddress = .unixDomainSocket(path: socketPath)
            case (.none, .none, .some(let address), .none):
                let components = address.split(separator: ":")
                let hostname = components.first.map { String($0) }
                let port = components.last.flatMap { Int($0) }
                self.bindAddress = .hostname(hostname, port: port)
            case let (hostname, port, .none, .none):
                self.bindAddress = .hostname(hostname ?? Defaults.hostname, port: port ?? Defaults.port)
            default:
                throw HTTPConfigurationError.incompatibleFlags
            }
        } catch {
            fatalError("Cannot read http server address provided via command line. Error: \(error)")
        }
        
        if let certPath = cert, let keyPath = keyPath {
            self.certURL = URL(fileURLWithPath: certPath)
            self.keyURL = URL(fileURLWithPath: keyPath)
        }
    }

    /// Configure application
    public func configure(_ app: Application) {
        do {
            if let certURL = certURL, let keyURL = keyURL {
                let certificates = try NIOSSLCertificate.fromPEMFile(certURL.path)
                let privateKey = try NIOSSLPrivateKey(file: keyURL.path, format: .pem)
                
                self.supportVersions.insert(.two)
                self.tlsConfiguration = .makeServerConfiguration(
                    certificateChain: certificates.map { .certificate($0) },
                    privateKey: .privateKey(privateKey)
                )
                
                app.logger.info("Using HTTP/2 and TLS.")
            } else {
                app.logger.info("No certificate or no key. Starting without HTTP/2.")
            }
        } catch {
            app.logger.warning("Cannot enable HTTP/2. Starting without HTTP/2. Error: \(error)")
        }
        
        app.storage[HTTPConfigurationStorageKey.self] = self
    }
    
    /// Sets the http server address
    public func address(_ address: BindAddress) -> Self {
        guard self.bindAddress == .hostname(Defaults.hostname, port: Defaults.port) else {
            return self
        }
        
        self.bindAddress = address
        return self
    }
    
    /// Sets the `.pem` file from which the certificate should be read.
    public func certificate(_ filePath: String) -> Self {
        guard self.certURL == nil else {
            return self
        }
        
        self.certURL = URL(fileURLWithPath: filePath)
        return self
    }

    /// Sets the `.pem` file from which the key should be read.
    public func key(_ filePath: String) -> Self {
        guard self.keyURL == nil else {
            return self
        }
        
        self.keyURL = URL(fileURLWithPath: filePath)
        return self
    }
}
