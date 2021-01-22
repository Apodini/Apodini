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
import OpenAPIKit


internal func makeError(code: Int = 0, _ message: String) -> Swift.Error {
    NSError(domain: "LambdaDeploy", code: code, userInfo: [
        NSLocalizedDescriptionKey: message
    ])
}


try Task.handleChildProcessInvocationIfNecessary()

typealias DeployedSystemStructure = DeployedSystemConfiguration


private func _findExecutable(_ name: String) throws -> URL {
    guard let url = Task.findExecutable(named: name) else {
        throw makeError("Unable to find executable '\(name)'")
    }
    return url
}

let dockerBin = try _findExecutable("docker")
let awsCliBin = try _findExecutable("aws")
let zipBin = try _findExecutable("zip")
let chmodBin = try _findExecutable("chmod") // TOOD just use the syscall instead?


let logger = Logger(label: "de.lukaskollmer.ApodiniLambda")


struct LambdaDeploymentProvider: DeploymentProvider, ParsableCommand {
    static let identifier: DeploymentProviderID = LambdaDeploymentProviderId
    static let version: Version = 1
    
    
    private var FM: FileManager { .default }
    
    @Argument
    var inputPackageRootDir: String
    
    @Option
    var productName: String
    
    @Option
    var awsProfileName: String = "default"
    
    @Option
    var awsS3BucketName: String = "apodini"
    
    @Option
    var awsApiGatewayApiId: String
    
    @Option // put all deployment groups into a single lambda. this is mainly here to improve performance when testing
    var singleLambda: Bool = true
    
    @Flag(help: "whether to skip the compilation steps and assume that build artifacts from a previous run are still located at the expected places")
    var awsDeployOnly: Bool = false
    
    
    var packageRootDir: URL {
        URL(fileURLWithPath: inputPackageRootDir)
    }
    
    
    
    var buildFolderUrl: URL {
        packageRootDir.appendingPathComponent(".build", isDirectory: true)
    }
    
    
    var tmpDirName: String { "lk_tmp" }
    
    var tmpDirUrl: URL {
        buildFolderUrl.appendingPathComponent(tmpDirName, isDirectory: true)
    }
    
    
    
    var lambdaOutputDir: URL {
        return buildFolderUrl
            .appendingPathComponent("lambda", isDirectory: true)
            .appendingPathComponent(productName, isDirectory: true)
    }
    
    
    
    func run() throws {
        if awsDeployOnly {
            logger.notice("Running with the --aws-deploy-only flag. Will skip compilation and try to re-use previous files")
        }
        logger.notice("initialising FileManager")
        try FM.lk_initialize()
        
        logger.notice("setting working directory to package root dir: \(packageRootDir)")
        try FM.lk_setWorkingDirectory(to: packageRootDir)
        
        logger.notice("creating directory at \(tmpDirUrl)")
        try FM.createDirectory(at: tmpDirUrl, withIntermediateDirectories: true, attributes: nil)
        
        
        logger.notice("preparing docker image")
        let dockerImageName = try prepareDockerImage()
        logger.notice("successfully built docker image. image name: \(dockerImageName)")
        
    
        logger.notice("generating web service structure")
        //let webServiceStructure = try readWebServiceStructure(usingDockerImage: dockerImageName)
        let webServiceStructure = try { () -> WebServiceStructure in
            if awsDeployOnly {
                let data = try Data(contentsOf: tmpDirUrl.appendingPathComponent("WebServiceStructure.json", isDirectory: false), options: [])
                return try JSONDecoder().decode(WebServiceStructure.self, from: data)
            } else {
                return try readWebServiceStructure(usingDockerImage: dockerImageName)
            }
        }()
        
        
        let nodes = try computeDefaultDeployedSystemNodes(
            from: webServiceStructure,
            overrideGrouping: singleLambda ? .singleNode : nil
        )
                
//        let node = try DeployedSystemStructure.Node(
//            id: "0", // todo make this the lambda function arn??
//            exportedEndpoints: webServiceStructure.endpoints,
//            userInfo: nil,
//            userInfoType: Null.self
//        )
        
        let deploymentStructure = try DeployedSystemStructure(
            deploymentProviderId: Self.identifier,
            currentInstanceNodeId: nodes[0].id,
            nodes: nodes,
            userInfo: nil,
            userInfoType: Null.self
        )
        
        
        let lambdaExecutableUrl: URL = awsDeployOnly
            //? //buildFolderUrl.appendingPathComponent("debug", isDirectory: true).appendingPathComponent(productName, isDirectory: false)
            ? tmpDirUrl.appendingPathComponent("lambda.out", isDirectory: false)
            : try compileForLambda(usingDockerImage: dockerImageName)
        
        
//        let lambdaExecutableUrl = packageRootDir
//            .appendingPathComponent(".build", isDirectory: true)
//            .appendingPathComponent("debug", isDirectory: true)
//            .appendingPathComponent(productName, isDirectory: false)
        logger.notice("Starting the AWS stuff")
        try AWSDeploymentStuff(
            awsProfileName: awsProfileName,
            deploymentStructure: deploymentStructure,
            openApiDocument: try JSONDecoder().decode(OpenAPI.Document.self, from: webServiceStructure.openApiDefinition),
            tmpDirUrl: self.tmpDirUrl,
            lambdaExecutableUrl: lambdaExecutableUrl,
            lambdaSharedObjectFilesUrl: lambdaOutputDir
        ).apply(
            s3BucketName: awsS3BucketName,
            s3ObjectFolderKey: "/lambda-code/",
            dstApiGateway: awsApiGatewayApiId == "_createNew" ? .createNew : .useExisting(awsApiGatewayApiId)
        )
        return
    }
    
    
    
    /// - returns: the name of the docker image
    func prepareDockerImage() throws -> String {
        let imageName = "apodini-lambda-builder"
        let task = Task(
            executableUrl: dockerBin,
            arguments: ["build", "-t", imageName, "."],
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        try task.launchSyncAndAssertSuccess()
        return imageName
    }
    
    
    
    
    func _runInDocker(imageName: String, bashCommand: String, workingDirectory: URL? = nil) throws {
        let task = Task(
            executableUrl: dockerBin,
            arguments: [
                "run", "--rm",
                "--volume", "\(packageRootDir.path):/src/",
                "--workdir", "/src/", imageName,
                "bash", "-cl", bashCommand
            ],
            workingDirectory: workingDirectory,
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        try task.launchSyncAndAssertSuccess()
    }
    
    
    func readWebServiceStructure(usingDockerImage dockerImageName: String) throws -> WebServiceStructure {
        let filename = "WebServiceStructure.json"
        try _runInDocker(
            imageName: dockerImageName,
            bashCommand: [
                "swift", "run", productName,
                WellKnownCLIArguments.exportWebServiceModelStructure, ".build/\(tmpDirName)/\(filename)" // can't use self.tmpDirUrl here since that's an absolute path but we need a relative one bc this is running in the docker container which has a different mount path
            ].joined(separator: " ")
        )
        let url = tmpDirUrl.appendingPathComponent(filename, isDirectory: false)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(WebServiceStructure.self, from: data) // TODO make this a WebServiceStructure initializer and remove all manual json decoding. same for the encoding. combine this w/ the launchInfo stuff, maybe into a nice protocol or smth like that
    }
    
    
    
    /// - returns: the directory containing all build artifacts (ie, the built executable and collected shared object files)
    func compileForLambda(usingDockerImage dockerImageName: String) throws -> URL {
        logger.notice("Compiling SPM target '\(productName)' for lambda")
//        let buildDockerImageTask = Task( //docker build -t builder .
//            executableUrl: dockerBin,
//            arguments: ["build", "-t", Self.dockerImageName, "."],
//            captureOutput: false,
//            launchInCurrentProcessGroup: true
//        )
//        try buildDockerImageTask.launchSyncAndAssertSuccess()
//        guard try buildDockerImageTask.launchSync().exitCode == EXIT_SUCCESS else {
//            throw makeError("Unable to build docker image")
//        }
        
//        let lambdaBuildArtifactsOutputDir = URL(fileURLWithPath: ".build/lambda/\(productName)/")
//        print("\n\nlambdaBuildArtifactsOutputDir", lambdaOutputDir.path, "\n\n")
        
        try _runInDocker(
            imageName: dockerImageName,
            bashCommand:
                "swift build --product \(productName) && ./collect-shared-object-files.sh .build/debug/\(productName) .build/lambda/\(productName)/"
        )
        
//        let runDockerContainerTask = Task(
//            executableUrl: dockerBin,
//            arguments: [
//                "run", "--rm",
//                "--volume", "\(packageRootDir.path):/src/",
//                "--workdir", "/src/", dockerImageName,
//                "bash", "-cl",
//                "swift build --product \(productName) && ./collect-shared-object-files.sh .build/debug/\(productName) .build/lambda/\(productName)/"
//            ],
//            captureOutput: false,
//            launchInCurrentProcessGroup: true
//        )
//        try runDockerContainerTask.launchSyncAndAssertSuccess()
//        guard try runDockerContainerTask.launchSync().exitCode == EXIT_SUCCESS else {
//            throw makeError("Error compiling web service for Lambda")
//        }
        
        let outputUrl = buildFolderUrl
            .appendingPathComponent("debug", isDirectory: true)
            .appendingPathComponent(productName, isDirectory: false)
        let dstExecutableUrl = tmpDirUrl.appendingPathComponent("lambda.out", isDirectory: false)
        try FM.lk_copyItem(at: outputUrl, to: dstExecutableUrl)
        return dstExecutableUrl
        
//        return buildFolderUrl
//            .appendingPathComponent("debug", isDirectory: true)
//            .appendingPathComponent(productName, isDirectory: false)
        //return lambdaBuildArtifactsOutputDir
        
        //return packageRootDir
        //    .appendingPathComponent(".build", isDirectory: true)
        //    .appendingPathComponent("debug", isDirectory: true)
        //    .appendingPathComponent(productName, isDirectory: false)
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
            arguments: [
                "--profile", "paul",
                "s3", "cp", "\(lambdaOutputDir.path)/lambda.zip", "s3://apodini/lambda-code/TestWebServiceAWS.zip"
            ],
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        try s3UploadTask.launchSyncAndAssertSuccess()
        
        let updateFunctionCodeTask = Task(
            executableUrl: awsCli,
            arguments: [
                "--profile", "paul",
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
//LambdaDeploymentProvider.main(["/Users/lukas/Developer/Apodini/", "--product-name=TestWebService"])

