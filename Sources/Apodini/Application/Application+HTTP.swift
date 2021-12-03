//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
//
// This code is based on the Vapor project: https://github.com/vapor/vapor
//
// SPDX-FileCopyrightText: 2020 Qutheory, LLC
//
// SPDX-License-Identifier: MIT
//               

import NIOSSL


/// The http major version
public enum HTTPVersionMajor: Equatable, Hashable {
    case one
    case two
}


/// BindAddress
public enum BindAddress: Equatable {
    case interface(_ address: String = HTTPConfiguration.Defaults.bindAddress, port: Int? = nil)
    case unixDomainSocket(path: String)
    
    public static func address(_ address: String) -> BindAddress {
        let components = address.split(separator: ":")
        let address = components.first.map { String($0) }
        let port = components.last.flatMap { Int($0) }
        return .interface(address!, port: port)
    }
}


/// Hostname
public struct Hostname {
    let address: String
    let port: Int?
    
    /// Create a new `Hostname`
    ///
    /// - parameters:
    ///     - address: Address part of hostname.
    ///     - port: Port of hostname.
    public init(address: String, port: Int? = nil) {
        self.address = address
        self.port = port
    }
}


/// Builds the TLS configuration from given paths for use in HTTPConfiguration
public struct TLSConfigurationBuilder {
    let tlsConfiguration: TLSConfiguration
    
    /// Create a new `TLSConfigurationBuilder`
    ///
    /// - parameters:
    ///     - certificatePath: Path to your certificate pem file.
    ///     - keyPath: Path to your key pem file.
    public init?(certificatePath: String, keyPath: String) {
        do {
            let certificate = try NIOSSLCertificate.fromPEMFile(certificatePath)
            let privateKey = try NIOSSLPrivateKey(file: keyPath, format: .pem)

            self.tlsConfiguration = .makeServerConfiguration(
                certificateChain: certificate.map { .certificate($0) },
                privateKey: .privateKey(privateKey)
            )
        } catch {
            print("Error while creating TLS Configuration: \(error)")
            return nil
        }
    }
}


extension Application {
    /// The HTTPConfiguration of the Application
    public var httpConfiguration: HTTPConfiguration {
        guard let httpConfiguration = self.storage[HTTPConfigurationStorageKey.self] else {
            let defaultConfig = HTTPConfiguration()
            defaultConfig.configure(self)
            return defaultConfig
        }
        return httpConfiguration
    }
}

/// HTTPConfigurationStorageKey
public struct HTTPConfigurationStorageKey: StorageKey {
    public typealias Value = HTTPConfiguration
}
