//
//  main.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-18.
//

import Foundation
import ApodiniDeployBuildSupport
import ApodiniUtils
import ArgumentParser
import DeploymentTargetAWSLambdaCommon
import SotoS3
import SotoLambda
import SotoApiGatewayV2
import OpenAPIKit



// TODO
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
let zipBin = try _findExecutable("zip")

let logger = Logger(label: "de.lukaskollmer.ApodiniLambda")





struct LambdaDeploymentProviderCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "AWS Lambda Apodini deployment provider",
        discussion: """
            Deploys an Apodini REST web service to AWS Lambda, mapping the deployed system's nodes to Lambda functions.
            Also configures an API Gateway to make the Lambda functions accessible over HTTP.
            """,
        version: String(LambdaDeploymentProvider.version)
    )
    
    @Argument(help: "Directory containing the Package.swift with the to-be-deployed web service's target")
    var inputPackageDir: String
    
    @Option(help: "Name of the web service's SPM target/product")
    var productName: String
    
    @Option
    var awsProfileName: String = "default"
    
    @Option
    var awsRegion: String = "eu-central-1"
    
    @Option(help: "Name of the S3 bucket to upload the lambda package to")
    var s3BucketName: String
    
    @Option(help: """
        Path of where in the bucket the lambda package should be stored.
        If a file already exists at the specified location (e.g. from a previous deployment) it will be overwritten.
        Note that this is only the folder path, and should not contain the actual filename.
        The lambda package will be stored at 's3://{bucket_name}/{bucket_path}/{product_name}.zip', where {product_name} is the name of the web service's target (as specified via the 'product-name' option).
        """
    )
    var s3BucketPath: String = "/apodini-lambda/"
    
    @Option
    var awsApiGatewayApiId: String
    
    @Flag(help: "whether to skip the compilation steps and assume that build artifacts from a previous run are still located at the expected places")
    var awsDeployOnly: Bool = false
    
    
    private(set) lazy var packageRootDir: URL = URL(fileURLWithPath: inputPackageDir).absoluteURL
    
    
    func run() throws {
        var deploymentProvider = LambdaDeploymentProvider(
            productName: productName,
            packageRootDir: URL(fileURLWithPath: inputPackageDir).absoluteURL,
            awsProfileName: awsProfileName,
            awsRegion: awsRegion,
            s3BucketName: s3BucketName,
            s3BucketPath: s3BucketPath,
            awsApiGatewayApiId: awsApiGatewayApiId,
            awsDeployOnly: awsDeployOnly
        )
        try deploymentProvider.run()
    }
}



private let dockerfileContents: String = """
FROM swift:5.3-amazonlinux2

ARG USER_ID
ARG GROUP_ID
ARG USERNAME

RUN yum -y install zip sqlite-devel

RUN groupadd --gid $GROUP_ID $USERNAME \
    && useradd -s /bin/bash --uid $USER_ID --gid $GROUP_ID -m $USERNAME

USER $USERNAME
"""


private let dockerignoreContents: String = """
.build/
"""



private let collectSharedObjectFilesScriptContents: String = """
#!/bin/bash
set -eu

executable_path=$1 # path to the built executable
output_dir=$2      # path of the directory we should copy the object files to

rm -rf "$output_dir"
mkdir -p "$output_dir"
# add the target deps based on ldd
ldd "$executable_path" | grep swift | awk '{print $3}' | xargs cp -L -t "$output_dir"
"""








struct LambdaDeploymentProvider: DeploymentProvider {
    static let identifier: DeploymentProviderID = LambdaDeploymentProviderId
    static let version: Version = 1
    
    let productName: String
    let packageRootDir: URL
    let awsProfileName: String
    let awsRegion: String
    let s3BucketName: String
    let s3BucketPath: String
    private(set) var awsApiGatewayApiId: String
    let awsDeployOnly: Bool
    
    private let FM = FileManager.default
    
    
    private var buildFolderUrl: URL {
        packageRootDir.appendingPathComponent(".build", isDirectory: true)
    }
    
    
    private var tmpDirName: String { "lk_tmp" }
    
    private var tmpDirUrl: URL {
        buildFolderUrl.appendingPathComponent(tmpDirName, isDirectory: true)
    }
    
    
    private var lambdaOutputDir: URL {
        buildFolderUrl
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
                guard let endpoint = endpoints.first, endpoints.count == 1 else {
                    return UUID().uuidString
                }
                return endpoint.handlerId.rawValue.replacingOccurrences(of: ".", with: "-")
            }
        )
        
        
        let awsIntegration = AWSDeploymentStuff(awsProfileName: awsProfileName, awsRegionName: awsRegion, tmpDirUrl: self.tmpDirUrl)
        
        if awsApiGatewayApiId == "_createNew" {
            awsApiGatewayApiId = try awsIntegration.createApiGateway(protocolType: .http)
        }
        
        let deploymentStructure = try DeployedSystemStructure(
            deploymentProviderId: Self.identifier,
            //currentInstanceNodeId: "", // we can safely set an invalid id here, because the
            nodes: nodes,
            userInfo: LambdaDeployedSystemContext(awsRegion: awsRegion, apiGatewayApiId: awsApiGatewayApiId)
        )
        
        
        let lambdaExecutableUrl: URL = awsDeployOnly
            ? tmpDirUrl.appendingPathComponent("lambda.out", isDirectory: false)
            : try compileForLambda(usingDockerImage: dockerImageName)
        
        
        logger.notice("Starting the AWS stuff")
        try awsIntegration.deployToLambda(
            deploymentStructure: deploymentStructure,
            openApiDocument: webServiceStructure.openApiDocument,
            lambdaExecutableUrl: lambdaExecutableUrl,
            lambdaSharedObjectFilesUrl: lambdaOutputDir,
            s3BucketName: s3BucketName,
            s3ObjectFolderKey: s3BucketPath,
            apiGatewayApiId: awsApiGatewayApiId
        )
        logger.notice("Done! Successfully applied the deployment.")
    }
    
    
    
    /// - returns: the name of the docker image
    private func prepareDockerImage() throws -> String {
        let imageName = "apodini-lambda-builder"
        let dockerfileUrl = tmpDirUrl.appendingPathComponent("Dockerfile", isDirectory: false)
        try dockerfileContents.write(to: dockerfileUrl, atomically: true, encoding: .utf8)
        try dockerignoreContents.write(to: dockerfileUrl.appendingPathExtension("dockerignore"), atomically: true, encoding: .utf8)
        let task = Task(
            executableUrl: dockerBin,
            arguments: [
                "build",
                "-f", dockerfileUrl.path,
                "-t", imageName,
                "--build-arg", "USER_ID=\(getuid())",
                "--build-arg", "GROUP_ID=\(getuid())",
                "--build-arg", "USERNAME=\(NSUserName())",
                "."
            ],
            captureOutput: false,
            launchInCurrentProcessGroup: true,
            environment: [
                "DOCKER_BUILDKIT": "1"
            ]
        )
        try task.launchSyncAndAssertSuccess()
        return imageName
    }
    
    
    
    
    private func runInDocker(imageName: String, bashCommand: String, workingDirectory: URL? = nil) throws {
        let task = Task(
            executableUrl: dockerBin,
            arguments: [
                "run", "--rm",
                "--volume", "\(packageRootDir.path)/..:/src/",
                "--workdir", "/src/\(packageRootDir.lastPathComponent)",
                imageName,
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
        return try WebServiceStructure(decodingJSONAt: url)
    }
    
    
    /// - returns: the directory containing all build artifacts (ie, the built executable and collected shared object files)
    private func compileForLambda(usingDockerImage dockerImageName: String) throws -> URL {
        logger.notice("Compiling SPM target '\(productName)' for lambda")
        // path of the shared object files script, relative to the docker container's root.
        let collectSharedObjectFilesScriptUrl = tmpDirUrl.appendingPathComponent("collect-shared-object-files.sh", isDirectory: false)
        try collectSharedObjectFilesScriptContents.write(to: collectSharedObjectFilesScriptUrl, atomically: true, encoding: .utf8)
        try FM.lk_setPosixPermissions("rwxr--r--", forItemAt: collectSharedObjectFilesScriptUrl)
        try runInDocker(
            imageName: dockerImageName,
            bashCommand:
                "swift build --product \(productName) && .build/lk_tmp/collect-shared-object-files.sh .build/debug/\(productName) .build/lambda/\(productName)/"
        )
        let outputUrl = buildFolderUrl
            .appendingPathComponent("debug", isDirectory: true)
            .appendingPathComponent(productName, isDirectory: false)
        let dstExecutableUrl = tmpDirUrl.appendingPathComponent("lambda.out", isDirectory: false)
        try FM.lk_copyItem(at: outputUrl, to: dstExecutableUrl)
        return dstExecutableUrl
    }
}


LambdaDeploymentProviderCLI.main()
