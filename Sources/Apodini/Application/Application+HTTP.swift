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
    case hostname(_ hostname: String? = HTTPConfiguration.Defaults.hostname, port: Int? = HTTPConfiguration.Defaults.port)
    case unixDomainSocket(path: String)
    
    public static func address(_ address: String) -> BindAddress {
        let components = address.split(separator: ":")
        let hostname = components.first.map { String($0) }
        let port = components.last.flatMap { Int($0) }
        return .hostname(hostname, port: port)
    }
}


/// TLSFilePaths for configuration in HTTPConfiguration
public struct TLSFilePaths {
    let certificatePath: String
    let keyPath: String
    
    /// Create a new `TLSFilePaths`
    ///
    /// - parameters:
    ///     - certificatePath: Path to your certificate pem file.
    ///     - keyPath: Path to your key pem file.
    public init(certificatePath: String, keyPath: String) {
        self.certificatePath = certificatePath
        self.keyPath = keyPath
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
