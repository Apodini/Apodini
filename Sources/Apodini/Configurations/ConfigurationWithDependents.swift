//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ArgumentParser

public protocol ConfigurationWithDependents: Configuration {
    var staticConfigurations: [DependentStaticConfiguration] { get }
}

extension ConfigurationWithDependents {
    public var command: ParsableCommand.Type {
        staticConfigurations.reduce(EmptyCommand.self) { (oldCommand: ParsableCommand.Type, staticConfiguration: DependentStaticConfiguration) in
            staticConfiguration.command ?? oldCommand
        }
    }
}
