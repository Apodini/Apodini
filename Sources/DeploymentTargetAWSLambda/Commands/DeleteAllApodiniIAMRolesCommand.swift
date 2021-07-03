//
//  DeleteAllApodiniIAMRolesCommand.swift
//  
//
//  Created by Paul Schmiedmayer on 7/3/21.
//

import ArgumentParser


struct DeleteAllApodiniIAMRolesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete-iam-roles",
        abstract: "Deletes *all* Apodini-related IAM roles from the AWS account. Use with caution."
    )
    
    
    @Option
    var awsRegion: String = "eu-central-1"
    
    @Option
    var awsProfileName: String?
    
    @Flag
    var dryRun = false
    
    
    func run() throws {
        let awsIntegration = AWSIntegration(
            awsRegionName: awsRegion,
            awsCredentials: Context.makeAWSCredentialProviderFactory(profileName: awsProfileName)
        )
        try awsIntegration.deleteAllApodiniIamRoles(isDryRun: dryRun)
    }
}
