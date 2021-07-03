//
//  AWSLambdaCLI.swift
//  
//
//  Created by Felix Desiderato on 02/07/2021.
//

import Foundation
import Apodini
import ArgumentParser
import DeploymentTargetAWSLambda

public struct AWSLambdaCLI<Service: Apodini.WebService>: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "aws",
            abstract: "AWS Lambda Apodini deployment provider",
            discussion: """
            Deploys an Apodini REST web service to AWS Lambda, mapping the deployed system's nodes to Lambda functions.
            Also configures an API Gateway to make the Lambda functions accessible over HTTP.
            """,
            version: "0.0.2"
        )
    }

    @OptionGroup
    var options: DeploymentCLI<Service>.Options
    
    @Option
    var awsProfileName: String?
    
    @Option
    var awsRegion: String = "eu-central-1"
    
    @Option(help: "Name of the S3 bucket to upload the lambda package to")
    var s3BucketName: String
    
    @Option(help: """
        Path of where in the bucket the lambda package should be stored.
        If a file already exists at the specified location (e.g. from a previous deployment), it will be overwritten.
        Note that this is only the folder path, and should not contain the actual filename.
        The lambda package will be stored at 's3://{bucket_name}/{bucket_path}/{product_name}.zip',
        where {product_name} is the name of the web service's target (as specified via the 'product-name' option).
        """
    )
    var s3BucketPath: String = "/apodini-lambda/"
    
    @Option(help: "Defines the AWS API Gateway ID that is used. If '_createNew' is passed in the deployment provider creates a new AWS API Gateway")
    var awsApiGatewayApiId: String
    
    @Option(help: """
        Whether to remove all existing Apodini Lambda functions created by this deployment provider before deeploying.
        
        Warning: Deletes all existing AWS Lambda functions with the 'apodini-lambda-{api_gateway_id}-' prefix!
                 ({api_gateway_id} is defined by the --aws-api-gateway-api-id option).
        
        Defaults to `true`.
        """
    )
    var deleteOldApodiniLambdaFunctions = true
    
    @Flag(help: "Whether to skip the compilation steps and assume that build artifacts from a previous run are still located at the expected places")
    var awsDeployOnly = false
    
    lazy var packageRootDir = URL(fileURLWithPath: options.inputPackageDir).absoluteURL
    
    
    public func run() throws {
        let service = Service()
        service.runSyntaxTreeVisitor()
        
        var deploymentProvider = AWSLambdaDeploymentProvider(
            productName: options.productName,
            packageRootDir: URL(fileURLWithPath: options.inputPackageDir).absoluteURL,
            awsProfileName: awsProfileName,
            awsRegion: awsRegion,
            s3BucketName: s3BucketName,
            s3BucketPath: s3BucketPath,
            awsApiGatewayApiId: awsApiGatewayApiId,
            awsDeployOnly: awsDeployOnly,
            deleteOldApodiniLambdaFunctions: deleteOldApodiniLambdaFunctions
        )
        try deploymentProvider.run()
    }
    
    public init() {}
}
