//
//  main.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-18.
//

import Foundation
import ApodiniDeployBuildSupport
import ArgumentParser
import DeploymentTargetAWSLambdaCommon
import SotoS3
import SotoLambda
import SotoApiGatewayV2


internal func makeError(code: Int = 0, _ message: String) -> Swift.Error {
    NSError(domain: "LambdaDeploy", code: code, userInfo: [
        NSLocalizedDescriptionKey: message
    ])
}


try Task.handleChildProcessInvocationIfNecessary()

typealias DeployedSystemStructure = DeployedSystemConfiguration


struct LambdaDeploymentProvider: DeploymentProvider, ParsableCommand {
    static let identifier: DeploymentProviderID = LambdaDeploymentProviderId
    static let version: Version = 1
    
    private static let dockerImageName = "apodini-lambda-builder"
    
    
    private var FM: FileManager { .default }
    
    @Argument
    var inputPackageRootDir: String
    
    @Option
    var productName: String
    
    
    var packageRootDir: URL {
        URL(fileURLWithPath: inputPackageRootDir)
    }
    
    
    var lambdaOutputDir: URL {
        return packageRootDir
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent("lambda", isDirectory: true)
            .appendingPathComponent(productName, isDirectory: true)
    }
    
    
    
    func run() throws {
        try FM.lk_initialize()
        try FM.lk_setWorkingDirectory(to: packageRootDir)
        
        let webServiceStructure = try generateWebServiceStructure()
        print(webServiceStructure)
        
        //let nodes = try computeDefaultDeployedSystemNodes(from: webServiceStructure)
        
        
        let node = try DeployedSystemStructure.Node(
            id: "0", // todo make this the lambda function arn??
            exportedEndpoints: webServiceStructure.endpoints,
            userInfo: nil,
            userInfoType: Null.self
        )
        
        let deploymentStructure = try DeployedSystemStructure(
            deploymentProviderId: Self.identifier,
            currentInstanceNodeId: node.id,
            nodes: [node],
            userInfo: nil,
            userInfoType: Null.self
        )
        
        let lambdaExecutableUrl = try compileForLambda()
        
        try deploy(deploymentStructure: deploymentStructure, lambdaExecutableUrl: lambdaExecutableUrl)
        return
    }
    
    
    func compileForLambda() throws -> URL {
        let dockerBin = Task.findExecutable(named: "docker")!
        
        
        let buildDockerImageTask = Task( //docker build -t builder .
            executableUrl: dockerBin,
            arguments: ["build", "-t", Self.dockerImageName, "."],
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        try buildDockerImageTask.launchSyncAndAssertSuccess()
//        guard try buildDockerImageTask.launchSync().exitCode == EXIT_SUCCESS else {
//            throw makeError("Unable to build docker image")
//        }
//        docker run \
//          --rm \
//          --volume "$(pwd):/src/" \
//          --workdir "/src/" \
//          builder \
//          bash -cl "swift build --product TestWebServiceAWS && ./package-lambda.sh TestWebServiceAWS"
        
        let runDockerContainerTask = Task(
            executableUrl: dockerBin,
            arguments: [
                "run", "--rm", "--volume", "\(packageRootDir.path):/src/", "--workdir", "/src/", Self.dockerImageName,
                "bash", "-cl", "swift build --product \(productName) && ./collect-shared-object-files.sh \(productName)"
            ],
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        try runDockerContainerTask.launchSyncAndAssertSuccess()
//        guard try runDockerContainerTask.launchSync().exitCode == EXIT_SUCCESS else {
//            throw makeError("Error compiling web service for Lambda")
//        }
        
        return packageRootDir
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent("debug", isDirectory: true)
            .appendingPathComponent(productName, isDirectory: false)
    }
    
    
    
    func deploy(deploymentStructure: DeployedSystemStructure, lambdaExecutableUrl: URL) throws {
        for node in deploymentStructure.nodes {
            let launchInfo = deploymentStructure.withCurrentInstanceNodeId(node.id)
            //let launchInfoUrl = FM.lk_getTemporaryFileUrl(fileExtension: "json")
            let launchInfoUrl = lambdaOutputDir.appendingPathComponent("launchConfig.json", isDirectory: false)
            try launchInfo.writeTo(url: launchInfoUrl)
            
            let bootstrapFileUrl = lambdaOutputDir.appendingPathComponent("bootstrap", isDirectory: false)
            try makeBootstrapFile(launchInfoFileUrl: launchInfoUrl, writeTo: bootstrapFileUrl)
            //let bootstrapFileTmpUrl = try makeBootstrapFile(launchInfoFileUrl: launchInfoUrl)
//            let bootstrapFileUrl = lambdaOutputDir.appendingPathComponent("bootstrap", isDirectory: false)
            //try FM.copyItem(
//                at: bootstrapFileTmpUrl,
//                to: lambdaOutputDir.appendingPathComponent("bootstrap", isDirectory: false)
//            )
            let makeBootstrapFileExecutableTask = Task(
                executableUrl: Task.findExecutable(named: "chmod")!,
                arguments: ["+x", bootstrapFileUrl.path],
                captureOutput: false,
                launchInCurrentProcessGroup: true
            )
            try makeBootstrapFileExecutableTask.launchSyncAndAssertSuccess()
            
            let allItems = try FM.contentsOfDirectory(atPath: lambdaOutputDir.path)
            print("ALL ITEMS", allItems)
            
            let packageLambdaTask = Task(
                executableUrl: Task.findExecutable(named: "zip")!,
                arguments: ["lambda.zip"] + allItems,
                workingDirectory: lambdaOutputDir,
                captureOutput: false,
                launchInCurrentProcessGroup: true
            )
            
            try packageLambdaTask.launchSyncAndAssertSuccess()
        }
        
        
        let awsCli = Task.findExecutable(named: "aws")!
        
        let s3UploadTask = Task(
            executableUrl: awsCli,
            arguments: ["s3", "cp", "\(lambdaOutputDir.path)/lambda.zip", "s3://apodini/lambda-code/TestWebServiceAWS.zip"],
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        try s3UploadTask.launchSyncAndAssertSuccess()
        
        let updateFunctionCodeTask = Task(
            executableUrl: awsCli,
            arguments: [
                "--region", "eu-central-1",
                "lambda", "update-function-code",
                "--function-name", "apodini-test-function",
                "--s3-bucket", "apodini",
                "--s3-key", "lambda-code/TestWebServiceAWS.zip"
            ],
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        try updateFunctionCodeTask.launchSyncAndAssertSuccess()
        
//        let region = SotoCore.Region.eucentral1
//        let client = AWSClient(credentialProvider: .configFile(), httpClientProvider: .createNew)
        
//        let s3 = S3(client: client, region: region)
//        let lambda = Lambda(client: client, region: region)
//        let apiGateway = ApiGatewayV2(client: client, region: region)
        
        
        //let req = Lambda.UpdateFunctionCodeRequest(functionName: "apodini-test-function", imageUri: <#T##String?#>, publish: <#T##Bool?#>, revisionId: <#T##String?#>, s3Bucket: <#T##String?#>, s3Key: <#T##String?#>, s3ObjectVersion: <#T##String?#>, zipFile: <#T##Data?#>)
    }
    
    
    private func makeBootstrapFile(launchInfoFileUrl: URL, writeTo dstUrl: URL) throws {
        //let dstUrl = FM.lk_getTemporaryFileUrl(fileExtension: nil)
        let bootstrapFileContents = """
        #!/bin/bash
        ./\(productName) \(WellKnownCLIArguments.launchWebServiceInstanceWithCustomConfig) ./\(launchInfoFileUrl.lastPathComponent)
        """
        try bootstrapFileContents.write(to: dstUrl, atomically: true, encoding: .utf8)
    }
}


LambdaDeploymentProvider.main()

