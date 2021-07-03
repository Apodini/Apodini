//
//  RemoveDeploymentCommand.swift
//  
//
//  Created by Paul Schmiedmayer on 7/3/21.
//

import ArgumentParser


struct RemoveDeploymentCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove-deployment",
        abstract: "Removes all AWS resources associated with the most recent deployment to the specified API Gateway.",
        discussion: """
            Use this command to "undo" the deployment of a web service and remove AWS resources created and configured by this deployment provider
            from an AWS account.
            """
    )
    
    
    @Option
    var awsRegion: String = "eu-central-1"
    
    @Option
    var awsProfileName: String?
    
    @Option
    var apiGatewayApiId: String
    
    @Option(help: "Whether the API Gateway itself should remain in the account after all other resources were removed")
    var keepApiGateway: Bool
    
    @Flag
    var dryRun = false
    
    
    func run() throws {
        let awsIntegration = AWSIntegration(
            awsRegionName: awsRegion,
            awsCredentials: Context.makeAWSCredentialProviderFactory(profileName: awsProfileName)
        )
        try awsIntegration.removeDeploymentRelatedResources(
            apiGatewayId: self.apiGatewayApiId,
            keepApiGateway: self.keepApiGateway,
            isDryRun: self.dryRun
        )
    }
}
