//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
// 

import Apodini


/// Configures the root path of all endpoints
public enum RootPath: ExpressibleByStringLiteral {
    /// A custom path defined by a String
    case path(String)
    /// The current version is used as a root path
    case version
    
    
    public init(stringLiteral: String) {
        self = .path(stringLiteral)
    }
    
    
    /// Creates an `EndpointPath` based on the `RootPath`.
    /// - Parameter version: The version used to create the EndpointPath
    public func endpointPath(withVersion version: Version) -> EndpointPath {
        switch self {
        case let .path(path):
            return .string(path)
        case .version:
            return version.pathComponent
        }
    }
}
