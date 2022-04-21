//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import ApodiniUtils
import class Apodini.AnyHandlerIdentifier
import ApodiniDeployerBuildSupport
import AWSLambdaDeploymentProviderCommon
import Logging
import NIO
import SotoLambda
import SotoApiGatewayV2
import SotoS3
import SotoS3FileTransfer
import SotoIAM
import SotoSTS
import OpenAPIKit

// swiftlint:disable force_unwrapping file_length


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
    private static let apodiniIamRolePath = "/apodini-service-role/"
    private static let ApodiniDeployerApiGatewayDescription = "Created by ApodiniDeployer"
    private static let ApodiniDeployerApiGatewayNamePrefix = "ApodiniDeployer."
    
    private let fileManager = FileManager.default
    private let logger = Logger(label: "apodini.ApodiniLambda.AWSIntegration")
    
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
    
    
    init(awsRegionName: String, awsCredentials: SotoCore.CredentialProviderFactory) {
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
    func deployToLambda( // swiftlint:disable:this function_parameter_count function_body_length
        deploymentStructure: LambdaDeployedSystem,
        openApiDocument: OpenAPI.Document,
        lambdaExecutableUrl: URL,
        lambdaSharedObjectFilesUrl: URL,
        s3BucketName: String,
        s3ObjectFolderKey: String,
        apiGatewayApiId: String,
        deleteOldApodiniLambdaFunctions: Bool,
        tmpDirUrl: URL,
        flattenedWebServiceArguments: String
    ) throws {
        guard !didRunDeployment else {
            fatalError("Cannot call '\(#function)' multiple times.")
        }
        didRunDeployment = true
        
        let accountId = try sts.getCallerIdentity(STS.GetCallerIdentityRequest()).wait().account!
        
        logger.notice("Fetching list of all lambda functions in AWS account")
        let allFunctions = try fetchAllLambdaFunctionsInAccount()
        logger.notice("Number of AWS lambda functions currently deployed: \(allFunctions.count) \(allFunctions.map(\.functionArn!))")
        
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
                ./\(lambdaExecutableUrl.lastPathComponent) ${\(WellKnownEnvironmentVariables.webServiceArguments)} deploy startup aws-lambda ${\(WellKnownEnvironmentVariables.fileUrl)} ${\(WellKnownEnvironmentVariables.currentNodeId)}
                """
                let bootstrapFileUrl = lambdaPackageTmpDir.appendingPathComponent("bootstrap", isDirectory: false)
                try bootstrapFileContents.write(to: bootstrapFileUrl, atomically: true, encoding: .utf8)
                try fileManager.setPosixPermissions("rwxrwxr-x", forItemAt: bootstrapFileUrl)
            }
            
            logger.notice("Zipping lambda package")
            let zipFilename = "lambda.zip"
            try ChildProcess(
                executableUrl: Context.zipBin,
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
                    ).wait()
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
        
        var nodeToLambdaFunctionMapping: [DeployedSystemNode.ID: Lambda.FunctionConfiguration] = [:]
        
        logger.notice("Creating lambda functions for nodes in the web service deployment structure (#nodes: \(deploymentStructure.nodes.count))")
        for node in deploymentStructure.nodes {
            logger.notice("Creating lambda function for node w/ id \(node.id) (handlers: \(node.exportedEndpoints.map { ($0.handlerType, $0.handlerId) }))")
            
            let functionConfig = try configureLambdaFunction(
                forNode: node,
                context: deploymentStructure.context,
                launchInfoFileUrl: launchInfoFileUrl,
                allFunctions: allFunctions,
                s3BucketName: s3BucketName,
                s3ObjectKey: s3ObjectKey,
                apiGatewayApiId: apiGatewayApiId,
                webServiceArguments: flattenedWebServiceArguments
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
                )).wait() // swiftlint:disable:this multiline_function_chains
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
                    throw Context.makeError("Unable to read handler id from OpenAPI operation object")
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
                    throw Context.makeError("Unable to read handler id from OpenAPI operation object")
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
        
        logger.notice("Importing API definition into the API Gateway")
        _ = try apiGateway.reimportApi(ApiGatewayV2.ReimportApiRequest(
            apiId: apiGatewayApiId,
            basepath: nil,
            body: String(
                data: try apiGatewayImportDef.encodeToJSON(outputFormatting: [.prettyPrinted, .withoutEscapingSlashes]),
                encoding: .utf8
            )!,
            failOnWarnings: false
        )).wait()
        
        logger.notice("Updating API Gateway name")
        _ = try apiGateway.updateApi(ApiGatewayV2.UpdateApiRequest(
            apiId: apiGatewayApiId,
            description: Self.ApodiniDeployerApiGatewayDescription,
            name: Self.ApodiniDeployerApiGatewayNamePrefix.appending(apiGatewayApiId)
        )).wait()
        
        let numLambdas = deploymentStructure.nodes.count
        logger.notice("Deployed \(numLambdas) lambda\(numLambdas == 1 ? "" : "s") to api gateway w/ id '\(apiGatewayApiId)'")
        logger.notice("Invoke URL: \(apiGatewayExecuteUrl)")
    }
    
    
    private func fetchOrCreateLambdaExecutionRole(forApiGatewayWithId apiGatewayId: String) throws -> IAM.Role {
        if let role = self.lambdaExecutionRole {
            return role
        }
        
        logger.notice("Looking if a suitable execution role exists in the AWS account")
        let allRoles = try fetchAllApodiniRelatedIamRoles()
        if let matchingRole = allRoles.first(where: { $0.roleName.hasPrefix("apodini.lambda.executionRole.\(apiGatewayId).") }) {
            self.lambdaExecutionRole = matchingRole
            return matchingRole
        }
        
        logger.notice("Creating IAM execution role for new functions")
        let request = IAM.CreateRoleRequest(
            assumeRolePolicyDocument:
                #"{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}"#,
            description: nil,
            path: Self.apodiniIamRolePath,
            permissionsBoundary: nil,
            roleName: "apodini.lambda.executionRole.\(apiGatewayId).\(Date().format("yyyy-MM-dd_HHmmss"))"
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
        forNode node: DeployedSystemNode,
        context: LambdaDeployedSystemContext,
        launchInfoFileUrl: URL,
        allFunctions: [Lambda.FunctionConfiguration],
        s3BucketName: String,
        s3ObjectKey: String,
        apiGatewayApiId: String,
        webServiceArguments: String
    ) throws -> Lambda.FunctionConfiguration {
        // lambda allowed function names regex:
        // #"(arn:(aws[a-zA-Z-]*)?:lambda:)?([a-z]{2}((-gov)|(-iso(b?)))?-[a-z]+-\d{1}:)?(\d{12}:)?(function:)?([a-zA-Z0-9-_]+)(:(\$LATEST|[a-zA-Z0-9-_]+))?"#
        let allowedCharacters = "abcdefghijklmnopqsrtuvwxyzABCDEFGHIJKLMNOPQSRTUVWXYZ0123456789-_"
        let lambdaName = "\(Self.lambdaFunctionNamePrefix)-\(apiGatewayApiId)-\(String(node.id.map { allowedCharacters.contains($0) ? $0 : "-" }))"
        guard deployedLambdaFunctions.insert(lambdaName).inserted else {
            fatalError("Encountered multiple lambda functions with same name '\(lambdaName)'. This can happen if two handler or deployment group identifiers are very similar and one of them contains invalid caracters, causing the sanitised name to match the other one.")
        }

        let memorySize = context.memoryMaximum
        let timeoutInSec = context.timeoutMaximum
        let lambdaEnv: Lambda.Environment = .init(variables: [
            WellKnownEnvironmentVariables.currentNodeId: node.id,
            WellKnownEnvironmentVariables.executionMode: WellKnownEnvironmentVariableExecutionMode.launchWebServiceInstanceWithCustomConfig,
            WellKnownEnvironmentVariables.fileUrl: launchInfoFileUrl.lastPathComponent,
            WellKnownEnvironmentVariables.webServiceArguments: webServiceArguments
        ])
        
        let executionRole = try fetchOrCreateLambdaExecutionRole(forApiGatewayWithId: apiGatewayApiId)
        logger.notice("Using lambda execution role: name='\(executionRole.roleName)' arn='\(executionRole.arn)'")
        
        if let function = allFunctions.first(where: { $0.functionName == lambdaName }) {
            logger.notice("Found existing lambda function w/ matching name. Updating code")
            _ = try lambda.updateFunctionConfiguration(Lambda.UpdateFunctionConfigurationRequest(
                environment: lambdaEnv,
                functionName: function.functionArn!,
                memorySize: memorySize,
                timeout: timeoutInSec
            )).wait()
            return try lambda
                .updateFunctionCode(Lambda.UpdateFunctionCodeRequest(
                    functionName: function.functionName!,
                    s3Bucket: s3BucketName,
                    s3Key: s3ObjectKey
                ))
                .map { functionConfiguration in
                    self.logger.notice("Deployed lambda function \(lambdaName)")
                    return functionConfiguration
                }
                .wait()
        } else {
            logger.notice("Creating new lambda function \(lambdaName)")
            let createFunctionRequest = Lambda.CreateFunctionRequest(
                code: .init(s3Bucket: s3BucketName, s3Key: s3ObjectKey),
                description: "Apodini-created lambda function aws:states:opt-out",
                environment: lambdaEnv,
                functionName: lambdaName,
                handler: "apodini.main", // doesn't actually matter
                memorySize: memorySize,
                packageType: .zip,
                publish: true,
                role: executionRole.arn,
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
                    return try lambda.createFunction(createFunctionRequest)
                        .map { functionConfiguration in
                            self.logger.notice("Deployed lambda function \(lambdaName)")
                            return functionConfiguration
                        }
                        .wait()
                } catch let error as LambdaErrorType {
                    guard
                        error.errorCode == LambdaErrorType.invalidParameterValueException.errorCode,
                        error.context?.message == "The role defined for the function cannot be assumed by Lambda.",
                        iteration < 7
                    else {
                        logger.error("Error creating lambda function: \(error)")
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


// MARK: Cleanup Actions


extension AWSIntegration {
    /// Goes through the AWS account and deletes (or, if applicable, unconfigures) all resources which are part of
    /// the Apodini web service deployed to the AWS API Gayway with the specified id.
    /// - parameter apiGatewayId: The identifier of the API Gateway to which the web service was deployed
    /// - parameter keepApiGateway: Whether the API Gateway should be kept in the AWS Account, or also deleted.
    ///             This option is useful to preserve the identifier associated with an API Gateway, which allows, for example,
    ///             to re-deploy the web service to that same API Gateway at a later date, without having to deal with chanhing ids.
    func removeDeploymentRelatedResources( // swiftlint:disable:this cyclomatic_complexity
        apiGatewayId: String,
        keepApiGateway: Bool,
        isDryRun: Bool
    ) throws {
        let allLambdas = try fetchAllLambdaFunctionsInAccount()
        let relevantLambdas = allLambdas.filter { lambda in
            guard let name = lambda.functionName else {
                return false
            }
            return name.hasPrefix("\(Self.lambdaFunctionNamePrefix)-\(apiGatewayId)")
        }
        
        let allIAMRoles = try fetchAllApodiniRelatedIamRoles()
        let relevantIAMRoles = allIAMRoles.filter { role in
            role.path == Self.apodiniIamRolePath && role.roleName.hasPrefix("apodini.lambda.executionRole.\(apiGatewayId)")
        }
        
        guard !relevantLambdas.isEmpty || !relevantIAMRoles.isEmpty else {
            logger.notice("No AWS resources belonging to AIP Gateway w/ id '\(apiGatewayId)' found.")
            return
        }
        
        guard !isDryRun else {
            logger.notice("Would delete the following lambda functions:")
            for lambda in relevantLambdas {
                logger.notice("- \(lambda.functionArn!)")
            }
            logger.notice("Would delete the following IAM roles:")
            for role in relevantIAMRoles {
                logger.notice("- \(role.arn)")
            }
            if !keepApiGateway {
                logger.notice("Would delete the API Gateway")
            } else {
                logger.notice("Would keep API Gateway, but delete all of its routes:")
                for route in try getAllRoutesInApiGateway(withApiId: apiGatewayId) {
                    logger.notice("- \(route.routeId!) (\(route.routeKey))")
                }
            }
            return
        }
        
        for lambda in relevantLambdas {
            logger.notice("Deleting lambda function with arn '\(lambda.functionArn!)'")
            try self.lambda.deleteFunction(Lambda.DeleteFunctionRequest(
                functionName: lambda.functionName!
            )).wait()
        }
        
        for role in relevantIAMRoles {
            logger.notice("Deleting IAM role with arn '\(role.arn)'")
            try deleteIamRole(role)
        }
        
        if !keepApiGateway {
            logger.notice("Deleting API Gateway w/ id '\(apiGatewayId)'")
            try apiGateway.deleteApi(ApiGatewayV2.DeleteApiRequest(
                apiId: apiGatewayId
            )).wait()
        } else {
            // We're told to keep the API Gateway around, so instead of deleting it we're just gonna gut it.
            // Note that we're intentionally not deleting the entire stage.
            // (it's created alongside the gateway itself, and set to auto-deploy, so the changes made here will be propagated anyway.)
            logger.notice("Removing all routes from API Gateway w/ id '\(apiGatewayId)'")
            let allRoutes = try getAllRoutesInApiGateway(withApiId: apiGatewayId)
            for route in allRoutes {
                logger.notice("- Deleting route \(route.routeId!) (\(route.routeKey))")
                try apiGateway.deleteRoute(ApiGatewayV2.DeleteRouteRequest(
                    apiId: apiGatewayId,
                    routeId: route.routeId!
                )).wait()
            }
        }
    }
    
    
    /// Attempts to delete _all_ IAM roles in the Apodini path, regardless of whether they are being used or not.
    func deleteAllApodiniIamRoles(isDryRun: Bool) throws {
        let allRoles = try fetchAllApodiniRelatedIamRoles()
        
        guard !allRoles.isEmpty else {
            logger.notice("No matching Apodini-related IAM roles found.")
            return
        }
        
        guard !isDryRun else {
            logger.notice("Would delete the following IAM roles:")
            for role in allRoles {
                logger.notice("- \(role.arn)")
            }
            return
        }
        
        for role in allRoles {
            try deleteIamRole(role)
        }
    }
}


// MARK: Soto Utility extensions

extension AWSIntegration {
    /// Returns all lambda functions in the AWS account
    private func fetchAllLambdaFunctionsInAccount() throws -> [Lambda.FunctionConfiguration] {
        var retval: [Lambda.FunctionConfiguration] = []
        var nextMarker: String?
        repeat {
            let response = try lambda.listFunctions(Lambda.ListFunctionsRequest(
                marker: nextMarker
            )).wait()
            retval.append(contentsOf: response.functions ?? [])
            nextMarker = response.nextMarker
        } while nextMarker != nil
        return retval
    }
    
    
    /// Returns all routes in the API Gateway with the specified id
    private func getAllRoutesInApiGateway(withApiId apiId: String) throws -> [ApiGatewayV2.Route] {
        var retval: [ApiGatewayV2.Route] = []
        var marker: String?
        repeat {
            let response = try apiGateway.getRoutes(ApiGatewayV2.GetRoutesRequest(
                apiId: apiId,
                maxResults: nil,
                nextToken: marker
            )).wait()
            marker = response.nextToken
            retval.append(contentsOf: response.items ?? [])
        } while marker != nil
        return retval
    }
    
    
    /// Returns all IAM roles related to ApodiniDeployer
    private func fetchAllApodiniRelatedIamRoles() throws -> [IAM.Role] {
        var retval: [IAM.Role] = []
        var nextMarker: String?
        repeat {
            let response = try iam.listRoles(IAM.ListRolesRequest(
                marker: nextMarker,
                maxItems: nil,
                pathPrefix: Self.apodiniIamRolePath
            )).wait()
            retval.append(contentsOf: response.roles)
            nextMarker = response.marker
        } while nextMarker != nil
        return retval
    }
    
    /// Returns all role policies which are attached to the specified role.
    private func getAttachedRolePolicies(forRole role: IAM.Role) throws -> [IAM.AttachedPolicy] {
        var retval: [IAM.AttachedPolicy] = []
        var marker: String?
        repeat {
            let response = try iam.listAttachedRolePolicies(IAM.ListAttachedRolePoliciesRequest(
                marker: marker,
                roleName: role.roleName
            )).wait()
            retval.append(contentsOf: response.attachedPolicies ?? [])
            marker = response.marker
        } while marker != nil
        return retval
    }
    
    
    /// Deletes the specified IAM role, also detaching any role policies currently attached to the role
    private func deleteIamRole(_ role: IAM.Role) throws {
        logger.notice("Deleting IAM role '\(role.arn)'")
        for attachedPolicy in try getAttachedRolePolicies(forRole: role) {
            logger.notice("- Detaching role policy '\(attachedPolicy.policyName ?? "(null)")'")
            try iam.detachRolePolicy(IAM.DetachRolePolicyRequest(
                policyArn: attachedPolicy.policyArn!,
                roleName: role.roleName
            )).wait()
        }
        try iam.deleteRole(.init(roleName: role.roleName)).wait()
    }
}
