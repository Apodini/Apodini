//
//  HTTP2Configuration.swift
//
//
//  Created by Moritz Schüll on 05.12.20.
//

import Foundation
import NIOSSL

/// A `Configuration` for HTTP/2 and TLS.
/// The configuration can be done in two ways, either via the
/// command line arguments --cert and --key or via the
/// functions `certificate` or `key`.
///
/// Example command line arguments:
/// --cert=/some/path/cert.pem
/// --key=/some/path/key.pem
///
/// Example of config via code:
/// ```
/// HTTP2Configuration()
///     .cerrtificate("/some/path/cert.pem")
///     .key("/some/path/key.pem")
/// ```
public final class HTTP2Configuration: Configuration {
    private var certURL: URL?
    private var keyURL: URL?
    
    public init(cert: String? = nil, keyPath: String? = nil) {
        if let certPath = cert, let keyPath = keyPath {
            self.certURL = URL(fileURLWithPath: certPath)
            self.keyURL = URL(fileURLWithPath: keyPath)
        }
    }

    public func configure(_ app: Application) {
        do {
            if let certURL = certURL, let keyURL = keyURL {
                let certificates = try NIOSSLCertificate.fromPEMFile(certURL.path)
                let privateKey = try NIOSSLPrivateKey(file: keyURL.path, format: .pem)
                
                app.http.supportVersions = [.one, .two]
                app.http.tlsConfiguration = .forServer(
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
    }

    /// Sets the `.pem` file from which the certificate should be read.
    public func certificate(_ filePath: URL) -> Self {
        guard self.certURL == nil else {
            return self
        }
        
        self.certURL = filePath
        
        return self
    }

    /// Sets the `.pem` file from which the key should be read.
    public func key(_ filePath: URL) -> Self {
        guard self.keyURL == nil else {
            return self
        }
        
        self.keyURL = filePath
        
        return self
    }
}
