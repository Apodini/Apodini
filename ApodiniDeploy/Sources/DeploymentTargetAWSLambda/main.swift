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



//struct A: ExpressibleByStringLiteral {
//    init?(_ value: String) {
//        print(#function)
//    }
//    init(stringLiteral value: String) {
//        print(#function)
//    }
//}
//
//_ = A("123")
//_ = A.init("123")


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
                //"--volume", "\(packageRootDir.path):/src/",
                //"--workdir", "/src/", imageName,
                "--volume", "\(packageRootDir.path)/..:/src/",
                "--workdir", "/src/\(packageRootDir.lastPathComponent)",
                imageName,
                "bash", "-cl", "pwd && ls -la .. && echo pre && \(bashCommand) && echo post"
            ],
            workingDirectory: workingDirectory,
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        try task.launchSyncAndAssertSuccess()
    }
    
    
    private func readWebServiceStructure(usingDockerImage dockerImageName: String) throws -> WebServiceStructure {
        let filename = "WebServiceStructure.json"
//        try runInDocker(
//            imageName: dockerImageName,
//            bashCommand: "swift build --product \(productName)"
//        )
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
        // path of the shared object files script, relative to the docker container's root.
        //let sharedObjectFilesScriptPath = ".build/lk_tmp/collect-shared-object-files.sh"
        let collectSharedObjectFilesScriptUrl = tmpDirUrl.appendingPathComponent("collect-shared-object-files.sh", isDirectory: false)
        try collectSharedObjectFilesScriptContents.write(to: collectSharedObjectFilesScriptUrl, atomically: true, encoding: .utf8)
        //try FM.lk_setPosixPermissions(0o744, forItemAt: collectSharedObjectFilesScriptUrl) // rwxr--r--
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

set -eux

# executable=$1
executable_path=$1 # path to the built executable
output_dir=$2      # path of the directory we should copy the object files to

# target=".build/lambda/$executable"
rm -rf "$output_dir"
mkdir -p "$output_dir"
# cp ".build/debug/$executable" "$target/"
# add the target deps based on ldd
ldd "$executable_path" | grep swift | awk '{print $3}' | xargs cp -Lv -t "$output_dir"
# zip lambda.zip *
"""


LambdaDeploymentProvider.main()
