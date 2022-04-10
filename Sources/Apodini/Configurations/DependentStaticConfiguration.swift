//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import ArgumentParser

/// `DependentStaticConfiguration`s are used to register static services dependent on the `InterfaceExporter`
public protocol DependentStaticConfiguration {
    var command: ParsableCommand { get }
}

extension DependentStaticConfiguration {
    public var command: ParsableCommand {
        EmptyCommand()
    }
}

public struct EmptyDependentStaticConfiguration: DependentStaticConfiguration { }
