//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ArgumentParser

public protocol DependableConfiguration: Configuration {
    associatedtype InternalConfiguration
    
    var staticConfigurations: [AnyDependentStaticConfiguration] { get }
}

extension DependableConfiguration {
    // swiftlint:disable identifier_name
    /// Collects all the commands from the `DependentStaticConfiguration`s and exports them for this `DependableConfiguration`
    public var _commands: [ParsableCommand.Type] {
        staticConfigurations.compactMap { (staticConfiguration: AnyDependentStaticConfiguration) in
            staticConfiguration.command
        }
    }
}
