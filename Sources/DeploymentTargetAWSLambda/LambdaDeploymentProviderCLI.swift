//
//  LambdaDeploymentProviderCLI.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-18.
//

import ArgumentParser


@main
struct LambdaDeploymentProviderCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "AWS Lambda Apodini deployment provider",
        discussion: """
            The AWS Lambda deployment provider implements functionality related to managing the deployment of Apodini web services to AWS Lambda.
            """,
        version: "0.0.1",
        subcommands: [DeployWebServiceCommand.self, RemoveDeploymentCommand.self, DeleteAllApodiniIAMRolesCommand.self],
        defaultSubcommand: DeployWebServiceCommand.self
    )
}
