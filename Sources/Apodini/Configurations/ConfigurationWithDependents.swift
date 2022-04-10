//
//  File.swift
//  
//
//  Created by Simon Bohnen on 4/9/22.
//

import Foundation
import ArgumentParser

public protocol ConfigurationWithDependents {
    var staticConfigurations: [DependentStaticConfiguration] { get }
    
    var command: ParsableCommand.Type { get }
}

extension ConfigurationWithDependents {
    var command: ParsableCommand {
        staticConfigurations.reduce(EmptyCommand()) { (_, staticConfiguration: DependentStaticConfiguration) in
            staticConfiguration.command
        }
    }
}
