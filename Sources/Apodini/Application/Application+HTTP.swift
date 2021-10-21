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
