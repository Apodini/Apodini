//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniUtils
import ApodiniNetworking


extension REST {
    /// Configuration of the `RESTInterfaceExporter`
    public struct ExporterConfiguration {
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
            /// - Parameter withVersion: The version used to create the EndpointPath
            public func endpointPath(withVersion version: Version) -> EndpointPath {
                switch self {
                case let .path(path):
                    return .string(path)
                case .version:
                    return version.pathComponent
                }
            }
        }
        
        /// The to be used `AnyEncoder` for encoding responses of the `RESTInterfaceExporter`
        public let encoder: AnyEncoder
        /// The to be used `AnyDecoder` for decoding requests to the `RESTInterfaceExporter`
        public let decoder: AnyDecoder
        /// Indicates whether the HTTP route is interpreted case-sensitivly
        public let caseInsensitiveRouting: Bool
        /// Configures if the current web service version should be used as a prefix for all HTTP paths
        public let rootPath: RootPath?
        
        
        /// Initializes the `RESTExporterConfiguration` of the `RESTInterfaceExporter`
        /// - Parameters:
        ///    - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
        ///    - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
        ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitivly
        public init(encoder: AnyEncoder = REST.defaultEncoder,
                    decoder: AnyDecoder = REST.defaultDecoder,
                    caseInsensitiveRouting: Bool = false,
                    rootPath: RootPath? = nil) {
            self.encoder = encoder
            self.decoder = decoder
            self.caseInsensitiveRouting = caseInsensitiveRouting
            self.rootPath = rootPath
        }
    }
}
