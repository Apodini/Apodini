//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//  

import ArgumentParser
import DeploymentTargetIoT

@main
struct LifxIotDeploymentCLI: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            abstract: "LIFX Deployment Provider",
            discussion: "Contains LIFX deployment related commands",
            version: "0.0.1",
            subcommands: [LifxDeployCommand.self, KillSessionCommand.self],
            defaultSubcommand: LifxDeployCommand.self
        )
    }
}
