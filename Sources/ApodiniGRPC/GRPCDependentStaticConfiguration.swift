//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini

/// `GRPCDependentStaticConfiguration`s are used to register static services dependend on the `GRPCInterfaceExporter`
public protocol GRPCDependentStaticConfiguration {
    /// A method that handels the configuration of dependend static exporters
    /// - Parameters:
    ///    - app: The `Vapor.Application` which is used to register the configuration in Apodini
    ///    - parentConfiguration: The `GRPCExporterConfiguration` of the parent of the dependend exporter
    func configure(_ app: Application, parentConfiguration: GRPC.ExporterConfiguration)
}

/// The default configuration is an `EmptyGRPCDependentStaticConfiguration`
public struct EmptyGRPCDependentStaticConfiguration: GRPCDependentStaticConfiguration {
    public func configure(_ app: Application, parentConfiguration: GRPC.ExporterConfiguration) { }
    
    public init() { }
}

extension Array where Element == GRPCDependentStaticConfiguration {
    /// A method that handels the configuration of dependend static exporters
    /// - Parameters:
    ///    - app: The `Vapor.Application` which is used to register the configuration in Apodini
    ///    - parentConfiguration: The `GRPCExporterConfiguration` of the parent of the dependend static exporters
    func configure(_ app: Application, parentConfiguration: GRPC.ExporterConfiguration) {
        forEach {
            $0.configure(app, parentConfiguration: parentConfiguration)
        }
    }
}
