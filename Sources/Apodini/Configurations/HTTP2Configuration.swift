//
//  HTTP2Configuration.swift
//
//
//  Created by Moritz Schüll on 05.12.20.
//

import Foundation
import NIOSSL
@_implementationOnly import ConsoleKit

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
    
    
    public convenience init() {
        self.init(arguments: CommandLine.arguments)
    }
    
    init(arguments: [String]) {
        var commandInput = CommandInput(arguments: arguments)
        let certAndKey = detect(from: &commandInput)
        self.certURL = certAndKey?.certURL
        self.keyURL = certAndKey?.keyURL
    }
    
    
    func detect(from commandInput: inout CommandInput) -> (certURL: URL, keyURL: URL)? {
        struct Signature: CommandSignature {
            @Option(name: "cert", short: "c", help: "Path of the certificate")
            var certPath: String?
            @Option(name: "key", short: "k", help: "Path of the key")
            var keyPath: String?
        }

        do {
            let signature = try Signature(from: &commandInput)

            if let certPath = signature.certPath, let keyPath = signature.keyPath {
                return (URL(fileURLWithPath: certPath), URL(fileURLWithPath: keyPath))
            } else {
                return nil
            }
        } catch {
            fatalError("Cannot read certificate / key file provided via command line. Error: \(error)")
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
        guard certURL == nil else {
            return self
        }
        
        certURL = filePath
        
        return self
    }

    /// Sets the `.pem` file from which the key should be read.
    public func key(_ filePath: URL) -> Self {
        guard keyURL == nil else {
            return self
        }
        
        keyURL = filePath
        
        return self
    }
}
