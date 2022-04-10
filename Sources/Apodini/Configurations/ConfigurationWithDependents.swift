//
//  File.swift
//  
//
//  Created by Simon Bohnen on 4/9/22.
//

import Foundation
import ArgumentParser

public protocol ConfigurationWithDependents: Configuration {
    var staticConfigurations: [DependentStaticConfiguration] { get }
}

extension ConfigurationWithDependents {
    public var command: ParsableCommand.Type {
        staticConfigurations.reduce(EmptyCommand.self) { (_, staticConfiguration: DependentStaticConfiguration) in
            staticConfiguration.command
        }
    }
}
