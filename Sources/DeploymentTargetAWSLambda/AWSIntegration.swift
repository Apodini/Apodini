//
//  AWSIntegration.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-19.
//

import Foundation
import ApodiniUtils
import class Apodini.AnyHandlerIdentifier
import ApodiniDeployBuildSupport
import DeploymentTargetAWSLambdaCommon
import Logging
import NIO
import SotoLambda
import SotoApiGatewayV2
import SotoS3
import SotoS3FileTransfer
import SotoIAM
import SotoSTS
import OpenAPIKit

// swiftlint:disable force_unwrapping


extension OpenAPIVendorExtensionKey where Value == String {
    static let apodiniHandlerId = OpenAPIVendorExtensionKey("x-apodiniHandlerId")
    static let amazonApiGatewayImportExportVersion = OpenAPIVendorExtensionKey("x-amazon-apigateway-importexport-version")
}

extension OpenAPIVendorExtensionKey where Value == [String: String] {
    static let amazonApiGatewayIntegration = OpenAPIVendorExtensionKey("x-amazon-apigateway-integration")
}


/// A type which interacts with AWS to create and configure ressources.
/// - Note: Instances of this class should not be re-used to apply multiple deployments.
class AWSIntegration { // swiftlint:disable:this type_body_length
    private static let lambdaFunctionNamePrefix = "apodini-lambda"
    
    private let tmpDirUrl: URL
    private let fileManager = FileManager.default
    private let logger = Logger(label: "de.lukaskollmer.ApodiniLambda.AWSIntegration")
    
    private let awsRegion: SotoCore.Region
    private let awsClient: AWSClient
    private let sts: STS
    private let iam: IAM
    private let s3: S3
    private let lambda: Lambda
    private let apiGateway: ApiGatewayV2
    
    private var didRunDeployment = false
    private var lambdaExecutionRole: IAM.Role?
    private var deployedLambdaFunctions: Set<String> = [] // Set of lambda function names
    
    
    init(
        awsRegionName: String,
        awsCredentials: SotoCore.CredentialProviderFactory,
        tmpDirUrl: URL
    ) {
        self.tmpDirUrl = tmpDirUrl
        awsRegion = .init(rawValue: awsRegionName)
        awsClient = AWSClient(
            credentialProvider: awsCredentials,
            retryPolicy: .exponential(),
            httpClientProvider: .createNew
        )
        sts = STS(client: awsClient, region: awsRegion)
        iam = IAM(client: awsClient)
        s3 = S3(client: awsClient, region: awsRegion, timeout: .minutes(4))
        lambda = Lambda(client: awsClient, region: awsRegion)
        apiGateway = ApiGatewayV2(client: awsClient, region: awsRegion)
    }
    
    
    deinit {
        try? awsClient.syncShutdown()
    }
    
    
    /// Creates a new HTTP API Gateway in the specified AWS region.
    /// - returns: on success, the newly created API's id
    func createApiGateway(protocolType: SotoApiGatewayV2.ApiGatewayV2.ProtocolType) throws -> String {
        let apiId = try apiGateway.createApi(ApiGatewayV2.CreateApiRequest(
            name: "apodini-tmp-api", // doesnt matter will be replaced when importing the openapi spec
            protocolType: protocolType
        )).wait().apiId!
        _ = try apiGateway.createStage(ApiGatewayV2.CreateStageRequest(
            apiId: apiId,
            autoDeploy: true,
            stageName: "$default"
        )).wait()
        return apiId
    }
    
    
    /// - parameter s3BucketName: name of the S3 bucket the function should be uploaded to
    /// - parameter s3ObjectFolderKey: key (ie path) of the folder into which the function should be uploaded
    func deployToLambda( // swiftlint:disable:this function_parameter_count function_body_length cyclomatic_complexity
        deploymentStructure: DeployedSystem,
        openApiDocument: OpenAPI.Document,
        lambdaExecutableUrl: URL,
        lambdaSharedObjectFilesUrl: URL,
        s3BucketName: String,
        s3ObjectFolderKey: String,
        apiGatewayApiId: String,
        deleteOldApodiniLambdaFunctions: Bool
    ) throws {
        guard !didRunDeployment else {
            fatalError("Cannot call '\(#function)' multiple times.")
        }
        didRunDeployment = true
        
        let accountId = try sts.getCallerIdentity(STS.GetCallerIdentityRequest()).wait().account!
        
        logger.notice("Fetching list of all lambda functions in AWS account")
        let allFunctions = try { [unowned self] () -> [Lambda.FunctionConfiguration] in
            var retval: [Lambda.FunctionConfiguration] = []
            var nextMarker: String?
            repeat {
                let response = try lambda.listFunctions(Lambda.ListFunctionsRequest(marker: nextMarker)).wait()
                retval.append(contentsOf: response.functions ?? [])
                nextMarker = response.nextMarker
            } while nextMarker != nil
            return retval
        }()
        logger.notice("Number of AWS lambda functions currently deployed: \(allFunctions.count) \(allFunctions.map(\.functionArn!))")

        
        // Delete old functions
        if deleteOldApodiniLambdaFunctions {
            do {
                let functionsToBeDeleted = allFunctions.filter { $0.functionName!.hasPrefix("\(Self.lambdaFunctionNamePrefix)-\(apiGatewayApiId)-") }
                if !functionsToBeDeleted.isEmpty {
                    logger.notice("Deleting old apodini lambda functions")
                    for function in functionsToBeDeleted {
                        logger.notice("Deleting \(function.functionName!)")
                        try lambda
                            .deleteFunction(Lambda.DeleteFunctionRequest(functionName: function.functionName!))
                            .wait()
                    }
                }
            }
        }
        
        
        //
        // Upload function code to S3
        //
        
        let s3ObjectKey = "\(s3ObjectFolderKey.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/\(lambdaExecutableUrl.lastPathComponent).zip"
        var launchInfoFileUrl: URL
        
        do {
            logger.notice("Creating lambda package")
            let lambdaPackageTmpDir = tmpDirUrl.appendingPathComponent("lambda-package", isDirectory: true)
            if fileManager.directoryExists(atUrl: lambdaPackageTmpDir) {
                try fileManager.removeItem(at: lambdaPackageTmpDir)
            }
            try fileManager.createDirectory(at: lambdaPackageTmpDir, withIntermediateDirectories: true, attributes: nil)
            
            let addToLambdaPackage = { [unowned self] (url: URL) throws -> Void in
                try fileManager.copyItem(
                    at: url,
                    to: lambdaPackageTmpDir.appendingPathComponent(url.lastPathComponent, isDirectory: false),
                    overwriteExisting: true
                )
            }
            
            for sharedObjectFileUrl in try fileManager.contentsOfDirectory(
                at: lambdaSharedObjectFilesUrl,
                includingPropertiesForKeys: nil,
                options: []
            ) {
                try addToLambdaPackage(sharedObjectFileUrl)
            }
            
            try addToLambdaPackage(lambdaExecutableUrl)
            
            launchInfoFileUrl = lambdaPackageTmpDir.appendingPathComponent("launchInfo.json", isDirectory: false)
            try deploymentStructure.writeJSON(to: launchInfoFileUrl)
            try fileManager.setPosixPermissions("rw-r--r--", forItemAt: launchInfoFileUrl)
            
            
            do {
                // create & add bootstrap file
                let bootstrapFileContents = """
                #!/bin/bash
                ./\(lambdaExecutableUrl.lastPathComponent)
                """
                let bootstrapFileUrl = lambdaPackageTmpDir.appendingPathComponent("bootstrap", isDirectory: false)
                try bootstrapFileContents.write(to: bootstrapFileUrl, atomically: true, encoding: .utf8)
                try fileManager.setPosixPermissions("rwxrwxr-x", forItemAt: bootstrapFileUrl)
            }
            
            logger.notice("zipping lambda package")
            let zipFilename = "lambda.zip"
            try Task(
                executableUrl: zipBin,
                arguments: try [zipFilename] + fileManager.contentsOfDirectory(atPath: lambdaPackageTmpDir.path),
                workingDirectory: lambdaPackageTmpDir,
                captureOutput: true, // suppress output
                launchInCurrentProcessGroup: true
            ).launchSyncAndAssertSuccess()
            
            do {
                let s3File = S3File(url: "s3://\(s3BucketName)/\(s3ObjectKey)")!
                logger.notice("Uploading lambda package to \(s3File.url)")
                let s3TransferManager = S3FileTransferManager(s3: s3, threadPoolProvider: .createNew)
                let fmt = NumberFormatter()
                fmt.numberStyle = .percent
                fmt.maximumFractionDigits = 0
                do {
                    try s3TransferManager.copy(
                        from: "\(lambdaPackageTmpDir.path)/\(zipFilename)",
                        to: s3File,
                        progress: { progress in
                            print(
                                "\u{1b}[2KS3 upload progress: \(fmt.string(from: NSNumber(value: progress)) ?? String(progress))",
                                terminator: "\r"
                            )
                            fflush(stdout)
                        }
                    ).wait() // swiftlint:disable:this multiline_function_chains
                    print("\u{1b}[2KS3 upload done.")
                } catch {
                    print("") // print a newline after the last progress line (which did not terminate w/ a newline)
                    throw error
                }
            }
        }
        
        
        //
        // Create new functions
        //
        
        var nodeToLambdaFunctionMapping: [DeployedSystem.Node.ID: Lambda.FunctionConfiguration] = [:]
        
        logger.notice("Creating lambda functions for nodes in the web service deployment structure (#nodes: \(deploymentStructure.nodes.count))")
        for node in deploymentStructure.nodes {
            logger.notice("Creating lambda function for node w/ id \(node.id) (handlers: \(node.exportedEndpoints.map { ($0.handlerType, $0.handlerId) }))")
            
            let functionConfig = try configureLambdaFunction(
                forNode: node,
                withInfoFileUrl: launchInfoFileUrl,
                //exportedEndpoint: exportedEndpoint,
                allFunctions: allFunctions,
                s3BucketName: s3BucketName,
                s3ObjectKey: s3ObjectKey,
                apiGatewayApiId: apiGatewayApiId
            )
            nodeToLambdaFunctionMapping[node.id] = functionConfig
            
            func grantLambdaPermissions(appiGatewayRessourcePattern pattern: String) throws {
                // https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html
                _ = try lambda.addPermission(Lambda.AddPermissionRequest(
                    action: "lambda:InvokeFunction",
                    functionName: functionConfig.functionName!,
                    principal: "apigateway.amazonaws.com",
                    sourceArn: "arn:aws:execute-api:\(awsRegion.rawValue):\(accountId):\(apiGatewayApiId)/\(pattern)",
                    statementId: UUID().uuidString.lowercased()
                )).wait()
            }
            try grantLambdaPermissions(appiGatewayRessourcePattern: "*/*/*")
            try grantLambdaPermissions(appiGatewayRessourcePattern: "*/$default")
        }
        
        
        //
        // API GATEWAY
        //
        
        let apiGatewayExecuteUrl = URL(string: "https://\(apiGatewayApiId).execute-api.\(awsRegion.rawValue).amazonaws.com/")!
        
        var apiGatewayImportDef = openApiDocument
        apiGatewayImportDef.vendorExtensions[.amazonApiGatewayImportExportVersion] = "1.0"
        apiGatewayImportDef.servers = [OpenAPI.Server(url: apiGatewayExecuteUrl)]
        
        func lambdaFunctionConfigForHandlerId(_ handlerId: String) -> Lambda.FunctionConfiguration {
            let node = deploymentStructure.nodeExportingEndpoint(withHandlerId: AnyHandlerIdentifier(handlerId))!
            return nodeToLambdaFunctionMapping[node.id]!
        }
        
        
        // Add lambda integration metadata for each endpoint
        apiGatewayImportDef.paths = try apiGatewayImportDef.paths.mapValues { (pathItem: OpenAPI.PathItem) -> OpenAPI.PathItem in
            var pathItem = pathItem
            for endpoint in pathItem.endpoints {
                var operation = endpoint.operation
                guard let handlerId = operation.vendorExtensions[.apodiniHandlerId] else {
                    throw makeError("Unable to read handler id from OpenAPI operation object")
                }
                let lambdaFunctionConfig = lambdaFunctionConfigForHandlerId(handlerId)
                operation.vendorExtensions[.amazonApiGatewayIntegration] = [
                    "type": "aws_proxy",
                    "httpMethod": "POST",
                    "connectionType": "INTERNET",
                    "uri": "arn:aws:apigateway:\(awsRegion.rawValue):lambda:path/2015-03-31/functions/\(lambdaFunctionConfig.functionArn!)/invocations",
                    "payloadFormatVersion": "2.0"
                ]
                pathItem.set(operation: operation, for: endpoint.method)
            }
            return pathItem
        }
        
        
        // Add the endpoints of the internal invocation API
        for (_, pathItem) in apiGatewayImportDef.paths {
            for endpoint in pathItem.endpoints {
                guard let handlerId: String = endpoint.operation.vendorExtensions[.apodiniHandlerId] else {
                    throw makeError("Unable to read handler id from OpenAPI operation object")
                }
                let lambdaFunctionConfig = lambdaFunctionConfigForHandlerId(handlerId)
                let path = OpenAPI.Path(["__apodini", "invoke", handlerId])
                apiGatewayImportDef.paths[path] = OpenAPI.PathItem(
                    post: OpenAPI.Operation(
                        responses: [
                            OpenAPI.Response.StatusCode.default: Either(OpenAPI.Response(description: "desc"))
                        ],
                        vendorExtensions: [
                            .init(.amazonApiGatewayIntegration, [
                                "type": "aws_proxy",
                                "httpMethod": "POST",
                                "connectionType": "INTERNET",
                                "uri": "arn:aws:apigateway:\(awsRegion.rawValue):lambda:path/2015-03-31/functions/\(lambdaFunctionConfig.functionArn!)/invocations",
                                "payloadFormatVersion": "2.0"
                            ])
                        ]
                    )
                )
            }
        }
        
        let reimportRequest = ApiGatewayV2.ReimportApiRequest(
            apiId: apiGatewayApiId,
            basepath: nil,
            body: String(
                data: try apiGatewayImportDef.encodeToJSON(outputFormatting: [.prettyPrinted, .withoutEscapingSlashes]),
                encoding: .utf8
            )!,
            failOnWarnings: true // Too strict?
        )
        
        _ = try apiGateway.reimportApi(reimportRequest).wait()
        
        let numLambdas = deploymentStructure.nodes.count
        logger.notice("Deployed \(numLambdas) lambda\(numLambdas == 1 ? "" : "s") to api gateway w/ id '\(apiGatewayApiId)'")
        logger.notice("Invoke URL: \(apiGatewayExecuteUrl)")
    }
    
    
    private func createLambdaExecutionRole() throws -> IAM.Role {
        if let role = lambdaExecutionRole {
            return role
        }
        
        // Note ideally this would look for existing roles and re-use them if possible
        logger.notice("Creating IAM execution role for new functions")
        let request = IAM.CreateRoleRequest(
            assumeRolePolicyDocument:
                #"{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}"#,
            description: nil,
            path: "/apodini-service-role/",
            permissionsBoundary: nil,
            roleName: "apodini.lambda.executionRole_\(Date().format("yyyy-MM-dd_HHmmss"))"
        )
        let role = try iam.createRole(request).wait().role
        logger.notice("Created lambda execution role: name='\(role.roleName)' arn='\(role.arn)'")
        
        func attachRolePolicy(arn: String) throws {
            logger.notice("Attaching permission policy '\(arn)' to role")
            try iam.attachRolePolicy(
                IAM.AttachRolePolicyRequest(
                    policyArn: arn,
                    roleName: role.roleName
                )
            ).wait()
        }
        
        try attachRolePolicy(arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole")
        try attachRolePolicy(arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaRole")
        
        self.lambdaExecutionRole = role
        return role
    }
    
    
    /// Configures a lambda function for a node within our deployed system.
    /// If a suitable function already exists (determined based on the node's id) this existing function will be re-used.
    /// Otherwise a new function will be created.
    /// - returns: the deployed-to function
    private func configureLambdaFunction( // swiftlint:disable:this function_body_length function_parameter_count
        forNode node: DeployedSystem.Node,
        withInfoFileUrl launchInfoFileUrl: URL,
        allFunctions: [Lambda.FunctionConfiguration],
        s3BucketName: String,
        s3ObjectKey: String,
        apiGatewayApiId: String
    ) throws -> Lambda.FunctionConfiguration {
        // lambda allowed function names regex:
        // #"(arn:(aws[a-zA-Z-]*)?:lambda:)?([a-z]{2}((-gov)|(-iso(b?)))?-[a-z]+-\d{1}:)?(\d{12}:)?(function:)?([a-zA-Z0-9-_]+)(:(\$LATEST|[a-zA-Z0-9-_]+))?"#
        let allowedCharacters = "abcdefghijklmnopqsrtuvwxyzABCDEFGHIJKLMNOPQSRTUVWXYZ0123456789-_"
        let lambdaName = "\(Self.lambdaFunctionNamePrefix)-\(apiGatewayApiId)-\(String(node.id.map { allowedCharacters.contains($0) ? $0 : "-" }))"
        guard deployedLambdaFunctions.insert(lambdaName).inserted else {
            fatalError("Encountered multiple lambda functions with same name '\(lambdaName)'. This can happen if two handler or deployment group identifiers are very similar and one of them contains invalid caracters, causing the sanitised name to match the other one.")
        }
        
        let deploymentOptions = node.combinedEndpointDeploymentOptions()
        let memorySize: UInt = try deploymentOptions.getValue(forKey: .memorySize).rawValue
        let timeoutInSec = Int((try deploymentOptions.getValue(forKey: .timeout) as ApodiniDeployBuildSupport.TimeoutValue).rawValue)
        let lambdaEnv: Lambda.Environment = .init(variables: [
            WellKnownEnvironmentVariables.currentNodeId: node.id,
            WellKnownEnvironmentVariables.executionMode: WellKnownEnvironmentVariableExecutionMode.launchWebServiceInstanceWithCustomConfig,
            WellKnownEnvironmentVariables.fileUrl: launchInfoFileUrl.lastPathComponent
        ])
        
        if let function = allFunctions.first(where: { $0.functionName == lambdaName }) {
            logger.notice("Found existing lambda function w/ matching name. Updating code")
            _ = try lambda.updateFunctionConfiguration(Lambda.UpdateFunctionConfigurationRequest(
                environment: lambdaEnv,
                functionName: function.functionArn!,
                memorySize: Int(memorySize),
                timeout: timeoutInSec
            )).wait()
            return try lambda.updateFunctionCode(Lambda.UpdateFunctionCodeRequest(
                functionName: function.functionName!,
                s3Bucket: s3BucketName,
                s3Key: s3ObjectKey
            )).wait()
        } else {
            logger.notice("Creating new lambda function \(lambdaName)")
            let executionRoleArn = try createLambdaExecutionRole().arn
            let createFunctionRequest = Lambda.CreateFunctionRequest(
                code: .init(s3Bucket: s3BucketName, s3Key: s3ObjectKey),
                description: "Apodini-created lambda function",
                environment: lambdaEnv,
                functionName: lambdaName,
                handler: "apodini.main", // doesn;t actually matter
                memorySize: Int(memorySize),
                packageType: .zip,
                publish: true,
                role: executionRoleArn,
                runtime: .providedAl2,
                tags: nil, // [String : String]?.none,
                timeout: timeoutInSec
            )
            
            // The issue here is that, if the IAM role assigned to the new lambda is a newly created role,
            // AWS doesn't always let us reference the role, and fails with a "The role defined for the function cannot be assumed by Lambda"
            // error message. There is in fact nothing wrong with the role (it can be assumed by the lambda), but
            // we, in some cases, have to wait a couple of seconds after creating the IAM role before we can create
            // a lambda function referencing it.
            // We work around this by, if the function creation failed, checking whether it failed because the IAM role
            // wasn't "ready" yet, and, if that is the case, retrying after a couple of seconds.
            // see also: https://stackoverflow.com/q/36419442
            func createLambdaImp(iteration: Int = 1) throws -> Lambda.FunctionConfiguration {
                do {
                    return try lambda.createFunction(createFunctionRequest).wait()
                } catch let error as LambdaErrorType {
                    guard
                        error.errorCode == LambdaErrorType.invalidParameterValueException.errorCode,
                        error.context?.message == "The role defined for the function cannot be assumed by Lambda.",
                        iteration < 7
                    else {
                        throw error
                    }
                    sleep(UInt32(2 * iteration)) // linear wait time. not perfect but whatever
                    return try createLambdaImp(iteration: iteration + 1)
                }
            }
            return try createLambdaImp()
        }
    }
}
