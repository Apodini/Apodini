//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import ArgumentParser

public protocol AnyDependentStaticConfiguration {
    var command: ParsableCommand.Type? { get }
    
    func configureAny(_ app: Application, parentConfiguration: Any)
}

extension AnyDependentStaticConfiguration {
    public var command: ParsableCommand.Type? { nil }
}

extension Array where Element == AnyDependentStaticConfiguration {
    /// A method that handles the configuration of dependent static exporters
    /// - Parameters:
    ///    - app: The `Application` which is used to register the configuration in Apodini
    ///    - parentConfiguration: The `Configuration` of the parent of the dependent static exporters
    public func configureAny(_ app: Application, parentConfiguration: Any) {
        forEach {
            $0.configureAny(app, parentConfiguration: parentConfiguration)
        }
    }
}

/// `DependentStaticConfiguration`s are used to register static services dependent on the `InterfaceExporter`
public protocol DependentStaticConfiguration: AnyDependentStaticConfiguration {
    associatedtype ParentConfiguration: ConfigurationWithDependents
    
    func configure(_ app: Application, parentConfiguration: ParentConfiguration.InternalConfiguration)
}

extension DependentStaticConfiguration {
    public func configureAny(_ app: Application, parentConfiguration: Any) {
        guard let typedConfiguration = parentConfiguration as? ParentConfiguration.InternalConfiguration else {
            return
        }
        
        self.configure(app, parentConfiguration: typedConfiguration)
    }
}

struct EmptyDependentStaticConfiguration<PConfiguration: ConfigurationWithDependents>: DependentStaticConfiguration {
    public typealias ParentConfiguration = PConfiguration
    
    public func configure(_ app: Application, parentConfiguration: PConfiguration.InternalConfiguration) { }
}
