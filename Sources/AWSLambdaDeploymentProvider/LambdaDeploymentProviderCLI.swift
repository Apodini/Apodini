//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import ArgumentParser


@main
struct LambdaDeploymentProviderCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "AWS Lambda Apodini Deployment Provider",
        discussion: """
            The AWS Lambda Deployment Provider implements functionality related to managing the deployment of Apodini web services to AWS Lambda.
            """,
        version: "0.0.1",
        subcommands: [DeployWebServiceCommand.self, RemoveDeploymentCommand.self, DeleteAllApodiniIAMRolesCommand.self],
        defaultSubcommand: DeployWebServiceCommand.self
    )
}
