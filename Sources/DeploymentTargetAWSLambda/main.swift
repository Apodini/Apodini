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


// This **must** be the very first statement in here! // TOOD might be able to get rid of this by forking instead?
try Task.handleChildProcessInvocationIfNecessary()


// TODO
// - need to encode the api gateway id into the lambda name, otherwise, if you want to deploy the same web service to multiple api gateways,
// it'd overwrite the existing lambdas (which are still being referenced by the other api geteway
// - aws ressource mgmt



internal func makeError(code: Int = 0, _ message: String) -> Swift.Error {
    NSError(domain: "LambdaDeploy", code: code, userInfo: [
        NSLocalizedDescriptionKey: message
    ])
}



private func _findExecutable(_ name: String) throws -> URL {
    guard let url = Task.findExecutable(named: name) else {
        throw makeError("Unable to find executable '\(name)'")
    }
    return url
}

let dockerBin = try _findExecutable("docker")
let awsCliBin = try _findExecutable("aws")
let zipBin = try _findExecutable("zip")
let FM = FileManager.default

let logger = Logger(label: "de.lukaskollmer.ApodiniLambda")

struct LambdaDeploymentProvider: DeploymentProvider, ParsableCommand {
    static let identifier: DeploymentProviderID = LambdaDeploymentProviderId
    static let version: Version = 1
    
    @Argument
    var inputPackageRootDir: String
    
    @Option
    var productName: String
    
    @Option
    var awsProfileName: String = "default"
    
    @Option
    var awsRegion: String = "eu-central-1"
    
    @Option
    var awsS3BucketName: String
    
    @Option
    var awsApiGatewayApiId: String
    
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
    
    
    
    mutating func run() throws {
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
            nodeIdProvider: { endpoints in
                assert(endpoints.count == 1)
                return endpoints[0].handlerIdRawValue.replacingOccurrences(of: ".", with: "-")
            }
        )
        
        
        let awsIntegration = AWSDeploymentStuff(awsProfileName: awsProfileName, awsRegionName: awsRegion, tmpDirUrl: self.tmpDirUrl)
        
        if awsApiGatewayApiId == "_createNew" {
            awsApiGatewayApiId = try awsIntegration.createApiGateway(protocolType: .http)
        }
        
        let deploymentStructure = try DeployedSystemStructure(
            deploymentProviderId: Self.identifier,
            currentInstanceNodeId: nodes[0].id,
            nodes: nodes,
            userInfo: LambdaDeployedSystemContext(awsRegion: awsRegion, apiGatewayApiId: awsApiGatewayApiId)
        )
        
        
        let lambdaExecutableUrl: URL = awsDeployOnly
            ? tmpDirUrl.appendingPathComponent("lambda.out", isDirectory: false)
            : try compileForLambda(usingDockerImage: dockerImageName)
        
        
        logger.notice("Starting the AWS stuff")
        try awsIntegration.deployToLambda(
            deploymentStructure: deploymentStructure,
            openApiDocument: try JSONDecoder().decode(OpenAPI.Document.self, from: webServiceStructure.openApiDefinition),
            lambdaExecutableUrl: lambdaExecutableUrl,
            lambdaSharedObjectFilesUrl: lambdaOutputDir,
            s3BucketName: awsS3BucketName,
            s3ObjectFolderKey: "/lambda-code/", // TODO read this from the CLI args? or make it dynamic based on the name of the web service?
            apiGatewayApiId: awsApiGatewayApiId
        )
        logger.notice("Done! Successfully applied the deployment.")
    }
    
    
    
    /// - returns: the name of the docker image
    private func prepareDockerImage() throws -> String {
        let imageName = "apodini-lambda-builder"
        let task = Task(
            executableUrl: dockerBin,
            arguments: [
                "build", "-t", imageName,
                "--build-arg", "USER_ID=\(getuid())",
                "--build-arg", "GROUP_ID=\(getuid())",
                "--build-arg", "USERNAME=\(NSUserName())",
                "."
            ],
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        try task.launchSyncAndAssertSuccess()
        return imageName
    }
    
    
    
    
    private func runInDocker(imageName: String, bashCommand: String, workingDirectory: URL? = nil) throws {
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
    
    
    private func readWebServiceStructure(usingDockerImage dockerImageName: String) throws -> WebServiceStructure {
        let filename = "WebServiceStructure.json"
        try runInDocker(
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
    private func compileForLambda(usingDockerImage dockerImageName: String) throws -> URL {
        logger.notice("Compiling SPM target '\(productName)' for lambda")
        try runInDocker(
            imageName: dockerImageName,
            bashCommand:
                "swift build --product \(productName) && ./collect-shared-object-files.sh .build/debug/\(productName) .build/lambda/\(productName)/"
        )
        let outputUrl = buildFolderUrl
            .appendingPathComponent("debug", isDirectory: true)
            .appendingPathComponent(productName, isDirectory: false)
        let dstExecutableUrl = tmpDirUrl.appendingPathComponent("lambda.out", isDirectory: false)
        try FM.lk_copyItem(at: outputUrl, to: dstExecutableUrl)
        return dstExecutableUrl
    }
}


LambdaDeploymentProvider.main()
