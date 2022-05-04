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


public protocol BindAddressProtocol {
    init(address: String, port: Int)
}


extension BindAddressProtocol {
    public init?(_ string: String) {
        let components = string.split(separator: ":")
        guard components.count == 2, let port = Int(components[1]) else {
            return nil
        }
        self.init(address: String(components[0]), port: port)
    }
}


/// :nodoc:
public struct BindAddressInput: BindAddressProtocol {
    public let address: String
    public let port: Int?
    
    public init(address: String, port: Int) {
        self.address = address
        self.port = port
    }
    
    public init(address: String = HTTPConfiguration.Defaults.bindAddress, port: Int? = nil) {
        self.address = address
        self.port = port
    }
}


/// A bind address, i.e. a combination of an address (e.g. a hostname) and a port
public struct BindAddress: Hashable, BindAddressProtocol {
    public let address: String
    public let port: Int

    public init(address: String, port: Int) {
        self.address = address
        self.port = port
    }
    
    /// Generates a address string representation based on the address and port.
    public func addressString() -> String {
        "\(address):\(port)"
    }
    
    /// Generates a URI-prefix suitable representation of this address.
    public func uriPrefix(isTLSEnabled: Bool, omitDefaultPorts: Bool = true) -> String {
        let scheme = "\(isTLSEnabled ? "https" : "http")"
        let portSuffix: String
        switch (omitDefaultPorts, port, isTLSEnabled) {
        case (true, HTTPConfiguration.Defaults.httpPort, false), (true, HTTPConfiguration.Defaults.httpsPort, true):
            portSuffix = ""
        default:
            portSuffix = ":\(port)"
        }
        return "\(scheme)://\(address)\(portSuffix)"
    }
}


@available(*, deprecated, renamed: "BindAddress")
public typealias Hostname = BindAddress


extension NIOSSL.TLSConfiguration {
    /// Creates a new `TLSConfiguration`, using the specified certificate and private key.
    public static func makeServerConfiguration(certificatePath: String, keyPath: String) throws -> Self {
        let cert = try NIOSSLCertificate.fromPEMFile(certificatePath)
        let key = try NIOSSLPrivateKey(file: keyPath, format: .pem)
        return .makeServerConfiguration(
            certificateChain: cert.map { .certificate($0) },
            privateKey: .privateKey(key)
        )
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
