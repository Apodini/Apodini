//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

/// `HTTPDependentStaticConfiguration`s are used to register static services dependent on the `HTTPInterfaceExporter`
public protocol HTTPDependentStaticConfiguration {
    /// A method that handles the configuration of dependent static exporters
    /// - Parameters:
    ///    - app: The `Application` which is used to register the configuration in Apodini
    ///    - parentConfiguration: The `HTTPExporterConfiguration` of the parent of the dependent exporter
    func configure(_ app: Application, parentConfiguration: HTTP.ExporterConfiguration)
}

/// The default configuration is an `EmptyHTTPDependentStaticConfiguration`
public struct EmptyHTTPDependentStaticConfiguration: HTTPDependentStaticConfiguration {
    public func configure(_ app: Application, parentConfiguration: HTTP.ExporterConfiguration) { }
    
    public init() { }
}

extension Array where Element == HTTPDependentStaticConfiguration {
    /// A method that handles the configuration of dependent static exporters
    /// - Parameters:
    ///    - app: The `Application` which is used to register the configuration in Apodini
    ///    - parentConfiguration: The `Configuration` of the parent of the dependent static exporters
    func configure(_ app: Application, parentConfiguration: HTTP.ExporterConfiguration) {
        forEach {
            $0.configure(app, parentConfiguration: parentConfiguration)
        }
    }
}
