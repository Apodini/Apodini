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
public class HTTP2Configuration: Configuration {
    private var certData: Data?
    private var keyData: Data?

    public convenience init() {
        self.init(arguments: CommandLine.arguments)
    }

    init(arguments: [String]) {
        do {
            var commandInput = CommandInput(arguments: arguments)
            try detect(from: &commandInput)
        } catch {
            print("Cannot read certificate / key file provided via command line. Error: \(error)")
        }
    }

    func detect(from commandInput: inout CommandInput) throws {
        struct Signature: CommandSignature {
            @Option(name: "cert", short: "c", help: "Path of the certificate")
            var certPath: String?
            @Option(name: "key", short: "k", help: "Path of the key")
            var keyPath: String?
        }

        let signature = try Signature(from: &commandInput)

        if let certPath = signature.certPath, let keyPath = signature.keyPath {
            certData = try Data(contentsOf: URL(fileURLWithPath: certPath))
            keyData = try Data(contentsOf: URL(fileURLWithPath: keyPath))
        } else {
            print("Cannot read certificate / key file provided via command line")
        }
    }

    public func configure(_ app: Application) {
        do {
            if let certData = certData,
               let keyData = keyData {
                let certificates = try NIOSSLCertificate.fromPEMBytes([UInt8](certData))
                let privateKey = try NIOSSLPrivateKey(bytes: [UInt8](keyData), format: .pem)
                app.http.supportVersions = [.one, .two]
                app.http.tlsConfiguration =
                    .forServer(certificateChain: certificates.map { .certificate($0) },
                               privateKey: .privateKey(privateKey))
                app.logger.info("Using HTTP/2 and TLS.")
            } else {
                app.logger.info("No certificate or no key. Starting without HTTP/2.")
            }
        } catch {
            print("Cannot enable HTTP/2. Starting without HTTP/2. Error: \(error)")
        }
    }

    /// Sets the `.pem` file from which the certificate should be read.
    public func certificate(_ filePath: String) -> Self {
        guard certData == nil else {
            return self
        }
        do {
            certData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            print("Cannot read certificate from file. Error: \(error)")
        }
        return self
    }

    /// Sets the `.pem` file from which the key should be read.
    public func key(_ filePath: String) -> Self {
        guard keyData == nil else {
            return self
        }
        do {
            keyData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            print("Cannot read key from file. Error: \(error)")
        }
        return self
    }
}
