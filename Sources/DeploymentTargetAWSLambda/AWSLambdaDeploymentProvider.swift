//
//  AWSLambdaDeploymentProvider.swift
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
import Apodini


internal func makeError(code: Int = 0, _ message: String) -> Swift.Error {
    NSError(domain: "LambdaDeploy", code: code, userInfo: [
        NSLocalizedDescriptionKey: message
    ])
}


private func _findExecutable(_ name: String) -> URL {
    guard let url = Task.findExecutable(named: name) else {
       fatalError("Unable to find executable '\(name)'")
    }
    return url
}

let dockerBin = _findExecutable("docker")
let zipBin = _findExecutable("zip")

let logger = Logger(label: "de.lukaskollmer.ApodiniLambda")


struct AWSLambdaDeploymentProvider: DeploymentProvider {
    static let identifier: DeploymentProviderID = lambdaDeploymentProviderId
    
    let productName: String
    let packageRootDir: URL
    let awsProfileName: String?
    let awsRegion: String
    let s3BucketName: String
    let s3BucketPath: String
    private(set) var awsApiGatewayApiId: String
    let awsDeployOnly: Bool
    let deleteOldApodiniLambdaFunctions: Bool
    
    var target: DeploymentProviderTarget {
        .spmTarget(packageUrl: packageRootDir, targetName: productName)
    }
    
    private let fileManager = FileManager.default
    
    private var buildFolderUrl: URL {
        packageRootDir.appendingPathComponent(".build", isDirectory: true)
    }
    
    private var tmpDirName: String { "ApodiniDeployTmp" }
    
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
        try fileManager.initialize()
        try fileManager.setWorkingDirectory(to: packageRootDir)
        try fileManager.createDirectory(at: tmpDirUrl, withIntermediateDirectories: true, attributes: nil)
        
        let dockerImageName = try prepareDockerImage()
        logger.notice("successfully built docker image. image name: \(dockerImageName)")
        
        logger.notice("retrieving web service structure")
        
        let webServiceStructure = try retrieveWebServiceStructure()
//        let webServiceStructure = try { () -> WebServiceStructure in
//            if awsDeployOnly {
//                let data = try Data(contentsOf: tmpDirUrl.appendingPathComponent("WebServiceStructure.json", isDirectory: false), options: [])
//                return try JSONDecoder().decode(WebServiceStructure.self, from: data)
//            } else {
//                return try readWebServiceStructure(usingDockerImage: dockerImageName)
//            }
//        }()
        logger.notice("computing default deployed system nodes")
        let nodes = try computeDefaultDeployedSystemNodes(
            from: webServiceStructure,
            nodeIdProvider: { endpoints in
                guard let endpoint = endpoints.first, endpoints.count == 1 else {
                    return UUID().uuidString
                }
                return endpoint.handlerId.rawValue.replacingOccurrences(of: ".", with: "-")
            }
        )
        
        let awsIntegration = AWSIntegration(
            awsRegionName: awsRegion,
            awsCredentials: {
                if let profileName = awsProfileName {
                    return .configFile(profile: profileName)
                } else if let credentials = readAwsCredentialsFromEnvironment() {
                    return .static(accessKeyId: credentials.accessKeyId, secretAccessKey: credentials.secretAccessKey)
                } else {
                    // if no profile name was explicitly specified, and we also were unable
                    // to find credentials in the environment variables, we fall back to the "default" profile
                    return .configFile(profile: "default")
                }
            }(),
            tmpDirUrl: self.tmpDirUrl
        )
        
        if awsApiGatewayApiId == "_createNew" {
            awsApiGatewayApiId = try awsIntegration.createApiGateway(protocolType: .http)
        }
        
        let deploymentStructure = try DeployedSystem(
            deploymentProviderId: Self.identifier,
            //currentInstanceNodeId: "", // we can safely set an invalid id here, because the
            nodes: nodes,
            userInfo: LambdaDeployedSystemContext(awsRegion: awsRegion, apiGatewayApiId: awsApiGatewayApiId)
        )
        
        
        let lambdaExecutableUrl: URL = awsDeployOnly
            ? tmpDirUrl.appendingPathComponent("lambda.out", isDirectory: false)
            : try compileForLambda(usingDockerImage: dockerImageName)
        
        logger.notice("Deploying to AWS")
        try awsIntegration.deployToLambda(
            deploymentStructure: deploymentStructure,
            openApiDocument: webServiceStructure.openApiDocument,
            lambdaExecutableUrl: lambdaExecutableUrl,
            lambdaSharedObjectFilesUrl: lambdaOutputDir,
            s3BucketName: s3BucketName,
            s3ObjectFolderKey: s3BucketPath,
            apiGatewayApiId: awsApiGatewayApiId,
            deleteOldApodiniLambdaFunctions: deleteOldApodiniLambdaFunctions
        )
        logger.notice("Done! Successfully applied the deployment.")
    }
    
    
    /// - returns: the name of the docker image
    private func prepareDockerImage() throws -> String {
        logger.notice("preparing docker image")
        let imageName = "apodini-lambda-builder"
        let dockerfileUrl = tmpDirUrl.appendingPathComponent("Dockerfile", isDirectory: false)
        guard
            let dockerfileBundleUrl = Bundle.module.url(forResource: "Dockerfile", withExtension: nil),
            let dockerignoreBundleUrl = Bundle.module.url(forResource: "dockerignore", withExtension: nil)
        else {
            throw makeError("Unable to locate docker resources in bundle")
        }
        
        try fileManager.copyItem(at: dockerfileBundleUrl, to: dockerfileUrl, overwriteExisting: true)
        try fileManager.copyItem(
            at: dockerignoreBundleUrl,
            to: dockerfileUrl.appendingPathExtension("dockerignore"),
            overwriteExisting: true
        )
        
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
    
    
    private func runInDocker(imageName: String, bashCommand: String, workingDirectory: URL? = nil, environment: [String: String?] = [:]) throws {
        let task = Task(
            executableUrl: dockerBin,
            arguments: [
                "run", "--rm",
                "--volume", "\(packageRootDir.path)/..:/src/",
                "--workdir", "/src/\(packageRootDir.lastPathComponent)",
                environment.reduce(into: "") { res, env in
                    guard let value = env.value else {
                        return
                    }
            
                    res.append(
                        """
                            --env \(env.key)='\(value)'
                        """ + " "
                    )
                },
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
                "swift", "run", productName
            ].joined(separator: " "),
            environment: [
                WellKnownEnvironmentVariables.executionMode: WellKnownEnvironmentVariableExecutionMode.exportWebServiceModelStructure,
                WellKnownEnvironmentVariables.fileUrl: ".build/\(tmpDirName)/\(filename)" // can't use self.tmpDirUrl here since that's an absolute path but we need a relative one bc this is running in the docker container which has a different mount path
            ]
        )
        let url = tmpDirUrl.appendingPathComponent(filename, isDirectory: false)
        return try WebServiceStructure(decodingJSONAt: url)
    }
    
    
    /// - returns: the directory containing all build artifacts (ie, the built executable and collected shared object files)
    private func compileForLambda(usingDockerImage dockerImageName: String) throws -> URL {
        logger.notice("Compiling SPM target '\(productName)' for lambda")
        let scriptFilename = "collect-shared-object-files.sh"
        do { // Copy the script into the temp dir, so that it can be run by the docker container
            guard let urlInBundle = Bundle.module.url(forResource: scriptFilename, withExtension: nil) else {
                throw makeError("Unable to find '\(scriptFilename)' resource in bundle")
            }
            let localUrl = tmpDirUrl.appendingPathComponent(scriptFilename, isDirectory: false)
            try fileManager.copyItem(at: urlInBundle, to: localUrl, overwriteExisting: true)
            try fileManager.setPosixPermissions("rwxr--r--", forItemAt: localUrl)
        }
        try runInDocker(
            imageName: dockerImageName,
            bashCommand:
                "swift build --product \(productName) && .build/\(tmpDirName)/\(scriptFilename) .build/debug/\(productName) .build/lambda/\(productName)/"
        )
        let outputUrl = buildFolderUrl
            .appendingPathComponent("debug", isDirectory: true)
            .appendingPathComponent(productName, isDirectory: false)
        let dstExecutableUrl = tmpDirUrl.appendingPathComponent("lambda.out", isDirectory: false)
        try fileManager.copyItem(at: outputUrl, to: dstExecutableUrl, overwriteExisting: true)
        return dstExecutableUrl
    }
    
    
    private func readAwsCredentialsFromEnvironment() -> (accessKeyId: String, secretAccessKey: String)? {
        let env = ProcessInfo.processInfo.environment
        if let accessKey = env["AWS_ACCESS_KEY_ID"], let secretAccessKey = env["AWS_SECRET_ACCESS_KEY"] {
            return (accessKey, secretAccessKey)
        } else {
            return nil
        }
    }
}
