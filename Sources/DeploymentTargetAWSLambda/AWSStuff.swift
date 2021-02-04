//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-19.
//

import Foundation
import Logging
import NIO
import SotoLambda
import SotoApiGatewayV2
import SotoIAM
import SotoSTS
import ApodiniDeployBuildSupport
import OpenAPIKit
import DeploymentTargetAWSLambdaCommon




/// A type which interacts with AWS to create and configure ressources.
/// - note: s
class AWSDeploymentStuff { // needs a better name
    private static let lambdaFunctionNamePrefix = "apodini-lambda"
    
    
    private let tmpDirUrl: URL
    
    private let FM = FileManager.default
    private let threadPool = NIOThreadPool(numberOfThreads: 1) // TODO make this 2 or more?
    
    private let awsProfileName: String
    private let awsRegion: SotoCore.Region
    private let awsClient: AWSClient
    private let sts: STS
    private let iam: IAM
    private let lambda: Lambda
    private let apiGateway: ApiGatewayV2
    
    private let logger = Logger(label: "de.lukaskollmer.ApodiniLambda.AWSIntegration")
    
    private var lambdaExecutionRole: IAM.Role?
    
    
    init(
        awsProfileName: String,
        awsRegionName: String,
        tmpDirUrl: URL
    ) {
        self.awsProfileName = awsProfileName
        self.awsRegion = .init(rawValue: awsRegionName)
        self.tmpDirUrl = tmpDirUrl
        awsClient = AWSClient(
            credentialProvider: .configFile(profile: awsProfileName),
            retryPolicy: .exponential(),
            httpClientProvider: .createNew
        )
        sts = STS(client: awsClient, region: awsRegion)
        iam = IAM(client: awsClient)
        lambda = Lambda(client: awsClient, region: awsRegion)
        apiGateway = ApiGatewayV2(client: awsClient, region: awsRegion)
    }
    
    
    deinit {
        logger.trace("-[\(Self.self) \(#function)]")
        try! awsClient.syncShutdown()
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
    func deployToLambda(
        deploymentStructure: DeployedSystemStructure,
        openApiDocument: OpenAPI.Document,
        lambdaExecutableUrl: URL,
        lambdaSharedObjectFilesUrl: URL,
        s3BucketName: String,
        s3ObjectFolderKey: String,
        apiGatewayApiId: String
    ) throws {
        logger.trace("-[\(Self.self) \(#function)]")
        
        let accountId = try sts.getCallerIdentity(STS.GetCallerIdentityRequest()).wait().account!
        
        logger.notice("Fetching list of all lambda functions in AWS account")
        let allFunctionsResponse = try lambda.listFunctions(Lambda.ListFunctionsRequest()).wait()
        
        if allFunctionsResponse.nextMarker != nil {
            logger.warning("nextMarker not nil!!!")
        }
        
        let allFunctions = allFunctionsResponse.functions ?? []
        logger.notice("#functions: \(allFunctions.count) \(allFunctions.map(\.functionArn!))")

        
        // Delete old functions
        do {
            let functionsToBeDeleted = allFunctions.filter { $0.functionName!.hasPrefix(Self.lambdaFunctionNamePrefix) }
            if !functionsToBeDeleted.isEmpty {
                logger.notice("Deleting old apodini lambda functions")
                for function in functionsToBeDeleted {
                    logger.notice("[SKIPPED] - deleting \(function.functionArn!)")
                    //try lambda
                    //    .deleteFunction(Lambda.DeleteFunctionRequest(functionName: function.functionName!))
                    //    .wait()
                }
            }
        }
        
        
        //
        // Create new functions
        //
        
        
        var nodeToLambdaFunctionMapping: [DeployedSystemStructure.Node.ID: Lambda.FunctionConfiguration] = [:]
        
        
        logger.notice("Creating lambda functions for nodes in the web service deployment structure (#nodes: \(deploymentStructure.nodes.count))")
        for node in deploymentStructure.nodes {
            guard let exportedEndpoint = node.exportedEndpoints.first, node.exportedEndpoints.count == 1 else {
                fatalError("In a Lambda deployment, each node must export exactly one endpoint")
            }
            logger.notice("Creating lambda function for node w/ id \(node.id) (handlers: \(node.exportedEndpoints.map { ($0.httpMethod, $0.absolutePath) })")
            
            logger.notice("Creating lambda package")
            let lambdaPackageTmpDir = tmpDirUrl.appendingPathComponent("lambda-package", isDirectory: true)
            if FM.lk_directoryExists(atUrl: lambdaPackageTmpDir) {
                try FM.removeItem(at: lambdaPackageTmpDir)
            }
            try FM.createDirectory(at: lambdaPackageTmpDir, withIntermediateDirectories: true, attributes: nil)
            
            let addToLambdaPackage = { [unowned self] (url: URL) throws -> Void in
                logger.notice("- adding \(url.lastPathComponent)")
                try FM.copyItem(
                    at: url,
                    to: lambdaPackageTmpDir.appendingPathComponent(url.lastPathComponent, isDirectory: false)
                )
            }
            
            for sharedObjectFileUrl in try FM.contentsOfDirectory(at: lambdaSharedObjectFilesUrl, includingPropertiesForKeys: nil, options: []) {
                try addToLambdaPackage(sharedObjectFileUrl)
            }
            
            try addToLambdaPackage(lambdaExecutableUrl)
            
            let launchInfoFileUrl = lambdaPackageTmpDir.appendingPathComponent("launchInfo.json", isDirectory: false)
            logger.notice("- adding launchInfo.json")
            try deploymentStructure.withCurrentInstanceNodeId(node.id).writeTo(url: launchInfoFileUrl)
            try FM.lk_setPosixPermissions("rw-r--r--", forItemAt: launchInfoFileUrl)
            
            do {
                // create & add bootstrap file
                logger.notice("- adding bootstrap")
                let bootstrapFileContents = """
                #!/bin/bash
                ./\(lambdaExecutableUrl.lastPathComponent) \(WellKnownCLIArguments.launchWebServiceInstanceWithCustomConfig) ./\(launchInfoFileUrl.lastPathComponent)
                """
                let bootstrapFileUrl = lambdaPackageTmpDir.appendingPathComponent("bootstrap", isDirectory: false)
                try bootstrapFileContents.write(to: bootstrapFileUrl, atomically: true, encoding: .utf8)
                try FM.lk_setPosixPermissions("rwxrwxr-x", forItemAt: bootstrapFileUrl)
            }
            
            logger.notice("zipping lambda package")
            let zipFilename = "lambda.zip"
            try Task(
                executableUrl: zipBin,
                arguments: try [zipFilename] + FM.contentsOfDirectory(atPath: lambdaPackageTmpDir.path),
                workingDirectory: lambdaPackageTmpDir,
                captureOutput: false,
                launchInCurrentProcessGroup: true
            ).launchSyncAndAssertSuccess()
            
            logger.notice("uploading lambda package to S3")
            
            let s3ObjectKey = "\(s3ObjectFolderKey.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/\(lambdaExecutableUrl.lastPathComponent).zip"
            
            try Task(
                executableUrl: awsCliBin,
                arguments: [
                    "--profile", awsProfileName,
                    "s3", "cp",
                    "\(lambdaPackageTmpDir.path)/\(zipFilename)",
                    "s3://\(s3BucketName)/\(s3ObjectKey)"
                ],
                captureOutput: false,
                launchInCurrentProcessGroup: true
            ).launchSyncAndAssertSuccess()
            
            
            let functionConfig = try configureLambdaFunction(
                forNode: node,
                exportedEndpoint: exportedEndpoint,
                allFunctions: allFunctions,
                s3BucketName: s3BucketName,
                s3ObjectKey: s3ObjectKey
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
        apiGatewayImportDef.vendorExtensions["x-amazon-apigateway-importexport-version"] = "1.0"
        
        apiGatewayImportDef.servers = [
            OpenAPI.Server(
                url: apiGatewayExecuteUrl,
                description: nil,
                variables: OrderedDictionary<String, OpenAPI.Server.Variable>(),
                vendorExtensions: Dictionary<String, AnyCodable>()
            )
        ]
        
        
        func lambdaFunctionConfigForHandlerId(_ handlerId: String) -> Lambda.FunctionConfiguration {
            let nodes = deploymentStructure.nodesExportingEndpoint(withHandlerId: handlerId)
            precondition(nodes.count == 1)
            let nodeId = nodes.first!.id
            return nodeToLambdaFunctionMapping[nodeId]!
        }
        
        
        // Add lambda integration metadata for each endpoint
        apiGatewayImportDef.paths = apiGatewayImportDef.paths.mapValues { (pathItem: OpenAPI.PathItem) -> OpenAPI.PathItem in
            var pathItem = pathItem
            for endpoint in pathItem.endpoints {
                var operation = endpoint.operation
                let handlerId = operation.vendorExtensions["x-handlerId"]!.value as! String
                let lambdaFunctionConfig = lambdaFunctionConfigForHandlerId(handlerId)
                operation.vendorExtensions["x-amazon-apigateway-integration"] = [
                    "type": "aws_proxy",
                    "httpMethod": "POST",
                    "connectionType": "INTERNET",
                    "uri": "arn:aws:apigateway:\(awsRegion.rawValue):lambda:path/2015-03-31/functions/\(lambdaFunctionConfig.functionArn!)/invocations",
                    "payloadFormatVersion": "2.0"
                ]
                //operation.vendorExtensions[Self.xAmazonApigatewayIntegrationKey] = AnyCodable(Self.makeApiGatewayOpenApiExtensionDict(awsRegion: awsRegion.rawValue, lambdaArn: lambdaFunctionConfig.functionArn!))
                
                // arn:aws:lambda:eu-central-1:873474603240:function:apodini-lambda-0
                //arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:012345678901:function:HelloWorld/invocations
                pathItem.set(operation: operation, for: endpoint.method)
            }
            return pathItem
        }
        
        
        // Add the endpoints of the internal invocation API
        for (path, pathItem) in apiGatewayImportDef.paths {
            for endpoint in pathItem.endpoints {
                let handlerId: String = endpoint.operation.vendorExtensions["x-handlerId"]?.value as! String
                let lambdaFunctionConfig = lambdaFunctionConfigForHandlerId(handlerId)
                let path = OpenAPI.Path(["__apodini", "invoke", handlerId])
                apiGatewayImportDef.paths[path] = OpenAPI.PathItem(
                    post: OpenAPI.Operation(
                        responses: [
                            OpenAPI.Response.StatusCode.default: Either(OpenAPI.Response.init(description: "desc"))
                        ],
                        vendorExtensions: [
                            Self.xAmazonApigatewayIntegrationKey: [
                                "type": "aws_proxy",
                                "httpMethod": "POST",
                                "connectionType": "INTERNET",
                                "uri": "arn:aws:apigateway:\(awsRegion.rawValue):lambda:path/2015-03-31/functions/\(lambdaFunctionConfig.functionArn!)/invocations",
                                "payloadFormatVersion": "2.0"
                            ]
                        ]
                    )
                )
            }
        }
        
        
//        apiGatewayImportDef.paths[OpenAPI.Path(rawValue: "/$default")] = OpenAPI.PathItem(
//            vendorExtensions: [
//                "x-amazon-apigateway-any-method": [
//                    "isDefaultRoute": true,
//                    Self.xAmazonApigatewayIntegrationKey: [
//                        "type": "aws_proxy",
//                        "httpMethod": "POST",
//                        "connectionType": "INTERNET",
//                        "uri": "arn:aws:apigateway:\(awsRegion.rawValue):lambda:path/2015-03-31/functions/\(nodeToLambdaFunctionMapping.first!.value.functionArn!)/invocations",
//                        "payloadFormatVersion": "2.0"
//                    ]
////                    Self.xAmazonApigatewayIntegrationKey: AnyCodable(Self.makeApiGatewayOpenApiExtensionDict(
////                        awsRegion: awsRegion.rawValue,
////                        lambdaArn: nodeToLambdaFunctionMapping.first!.value.functionArn! // TODO we can do better than this
////                    ))
////                    "x-amazon-apigateway-integration": [
////                        "type": "aws_proxy",
////                        "httpMethod": "POST",
////                        "connectionType": "INTERNET",
////                        "uri": "arn:aws:apigateway:\(awsRegion.rawValue):lambda:path/2015-03-31/functions/\(nodeToLambdaFunctionMapping.first!.value.functionArn!)/invocations",
////                        //"uri": lambdaFunctionConfig.functionArn!,
////                        //"credentials": lambdaFunctionConfig.role!,
////                        "payloadFormatVersion": "2.0"
////                    ]
//                ]
//            ]
//        )
        
        let openApiDefPath = self.tmpDirUrl.appendingPathComponent("openapi.json", isDirectory: false)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        try encoder.encode(apiGatewayImportDef).write(to: openApiDefPath)
        
        let reimportRequest = ApiGatewayV2.ReimportApiRequest(
            apiId: apiGatewayApiId,
            basepath: nil, // TODO?
            body: String(data: try Data(contentsOf: openApiDefPath), encoding: .utf8)!,
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
        
        // TODO look for existing roles and re-use is possible!
        logger.notice("Creating IAM execution role for new functions")
        let request = IAM.CreateRoleRequest(
            //assumeRolePolicyDocument: "", // TODO
            assumeRolePolicyDocument:
                #"{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}"#,
            description: nil,
            path: "/apodini-service-role/",
            permissionsBoundary: nil,
            //roleName: "apodini.lambda.executionRole_\(Date().lk_iso8601(includeTime: true))"
            roleName: "apodini.lambda.executionRole_\(Date().lk_format("yyyy-MM-dd_HHmmss"))"
        )
        print(request.roleName)
        let role = try iam.createRole(request).wait().role
        logger.notice("New role: name=\(role.roleName) arn=\(role.arn)")
        
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
    private func configureLambdaFunction(
        forNode node: DeployedSystemStructure.Node,
        exportedEndpoint: ExportedEndpoint,
        allFunctions: [Lambda.FunctionConfiguration],
        s3BucketName: String,
        s3ObjectKey: String
    ) throws -> Lambda.FunctionConfiguration {
        // TODO?
//        let lambdaNameRegex = try NSRegularExpression(
//            pattern: #"(arn:(aws[a-zA-Z-]*)?:lambda:)?([a-z]{2}((-gov)|(-iso(b?)))?-[a-z]+-\d{1}:)?(\d{12}:)?(function:)?([a-zA-Z0-9-_]+)(:(\$LATEST|[a-zA-Z0-9-_]+))?"#,
//            options: []
//        )
        let allowedCharacters = "abcdefghijklmnopqsrtuvwxyzABCDEFGHIJKLMNOPQSRTUVWXYZ0123456789-_"
        let lambdaName = "\(Self.lambdaFunctionNamePrefix)-\(String(node.id.map { allowedCharacters.contains($0) ? $0 : "-" }))"
        // TODO make sure we dont acidentally update the same function twice (eg once bc the unmodified name matches and once bc we replace something, which makes it match the other function's name)
        
        let memorySize: Int = try exportedEndpoint.deploymentOptions.getValue(forOptionKey: LambdaHandlerOption.memorySize)
        let timeout: Int = try exportedEndpoint.deploymentOptions.getValue(forOptionKey: LambdaHandlerOption.timeout)
        
        if let function = allFunctions.first(where: { $0.functionName == lambdaName }) {
            logger.notice("Found existing lambda function w/ matching name. Updating code")
            _ = try lambda.updateFunctionConfiguration(Lambda.UpdateFunctionConfigurationRequest(
                //description: <#T##String?#>,
                //environment: <#T##Lambda.Environment?#>,
                functionName: function.functionArn!,
                //handler: <#T##String?#>,
                memorySize: memorySize,
                //role: <#T##String?#>,
                timeout: timeout
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
                environment: nil, //.init(variables: [String : String]?.none), // TODO?
                functionName: lambdaName,
                handler: "apodini.main", // doesn;t actually matter
                memorySize: memorySize,
                packageType: .zip,
                publish: true,
                role: executionRoleArn,
                runtime: .providedAl2,
                tags: nil, // [String : String]?.none,
                timeout: timeout
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
                    print("ughhh")
                    let retval = try lambda.createFunction(createFunctionRequest).wait()
                    print("done!")
                    return retval
                } catch let error as LambdaErrorType {
                    guard
                        error.errorCode == LambdaErrorType.invalidParameterValueException.errorCode,
                        error.context?.message == "The role defined for the function cannot be assumed by Lambda.",
                        iteration < 7
                    else {
                        print("fuuuck", error)
                        throw error
                    }
                    sleep(UInt32(2 * iteration)) // linear wait time. not perfect but whatever
                    return try createLambdaImp(iteration: iteration + 1)
                }
            }
            return try createLambdaImp()
        }
    }
    
    
    
    
    static let xAmazonApigatewayIntegrationKey = "x-amazon-apigateway-integration"
    
    // This doesnt work because it'd result in doubly-wrapped `AnyCodable`s, which isn't supported
//    static func makeApiGatewayOpenApiExtensionDict(awsRegion: String, lambdaArn: String) -> [String: String] {
//        return [
//            "type": "aws_proxy",
//            "httpMethod": "POST",
//            "connectionType": "INTERNET",
//            "uri": "arn:aws:apigateway:\(awsRegion):lambda:path/2015-03-31/functions/\(lambdaArn)/invocations",
//            //"uri": lambdaFunctionConfig.functionArn!,
//            //"credentials": lambdaFunctionConfig.role!,
//            "payloadFormatVersion": "2.0"
//        ]
//    }
}




extension Date {
    func lk_iso8601(includeTime: Bool = false) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        if includeTime {
            fmt.formatOptions.formUnion([.withTime])
        }
        return fmt.string(from: self)
    }
    
    func lk_format(_ formatString: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = formatString
        return fmt.string(from: self)
    }
}
