//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
