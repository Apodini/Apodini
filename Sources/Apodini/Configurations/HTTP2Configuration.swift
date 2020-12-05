//
//  HTTP2Configuration.swift
//  
//
//  Created by Moritz Schüll on 05.12.20.
//

import Foundation
import Vapor
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
public class HTTP2Configuration: Configuration {
    private var certData: Data?
    private var keyData: Data?

    public init() {
        do {
            for arg in CommandLine.arguments {
                if arg.starts(with: "--cert=") {
                    certData = try Data(contentsOf: URL(fileURLWithPath: arg.substring(from: 7)))
                } else if arg.starts(with: "--key=") {
                    keyData = try Data(contentsOf: URL(fileURLWithPath: arg.substring(from: 6)))
                }
            }
        } catch { }
    }

    public func configure(_ app: Application) {
        do {
            if let certData = certData,
               let keyData = keyData {
                let certificates = try NIOSSLCertificate.fromPEMBytes([UInt8](certData))
                let privateKey = try NIOSSLPrivateKey.init(bytes: [UInt8](keyData), format: .pem)
                app.http.server.configuration.supportVersions = [.one, .two]
                app.http.server.configuration.tlsConfiguration =
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
        do {
            certData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            print("Cannot read certificate from file. Error: \(error)")
        }
        return self
    }

    /// Sets the `.pem` file from which the key should be read.
    public func key(_ filePath: String) -> Self {
        do {
            keyData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            print("Cannot read key from file. Error: \(error)")
        }
        return self
    }
}

extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }
}
