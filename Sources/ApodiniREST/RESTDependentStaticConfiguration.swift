//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini

/// `RESTDependentStaticConfiguration`s are used to register static services dependend on the `RESTInterfaceExporter`
public protocol RESTDependentStaticConfiguration {
    /// A method that handels the configuration of dependend static exporters
    /// - Parameters:
    ///    - app: The `Vapor.Application` which is used to register the configuration in Apodini
    ///    - parentConfiguration: The `RESTExporterConfiguration` of the parent of the dependend exporter
    func configure(_ app: Application, parentConfiguration: REST.ExporterConfiguration)
}

/// The default configuration is an `EmptyRESTDependentStaticConfiguration`
public struct EmptyRESTDependentStaticConfiguration: RESTDependentStaticConfiguration {
    public func configure(_ app: Application, parentConfiguration: REST.ExporterConfiguration) { }
    
    public init() { }
}

extension Array where Element == RESTDependentStaticConfiguration {
    /// A method that handels the configuration of dependend static exporters
    /// - Parameters:
    ///    - app: The `Vapor.Application` which is used to register the configuration in Apodini
    ///    - parentConfiguration: The `Configuration` of the parent of the dependend static exporters
    func configure(_ app: Application, parentConfiguration: REST.ExporterConfiguration) {
        forEach {
            $0.configure(app, parentConfiguration: parentConfiguration)
        }
    }
}
