//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-19.
//

import Foundation
import Logging
import NIO
import SotoS3
import SotoLambda
import SotoApiGatewayV2
import SotoIAM
import SotoSTS
import ApodiniDeployBuildSupport
import OpenAPIKit



class AWSDeploymentStuff { // needs a better name
    private let deploymentStructure: DeployedSystemStructure
    private let openApiDocument: OpenAPI.Document
    private let tmpDirUrl: URL
    private let lambdaExecutableUrl: URL
    private let lambdaSharedObjectFilesUrl: URL
    
    private let FM = FileManager.default
    
    private let threadPool = NIOThreadPool(numberOfThreads: 1) // TODO make this 2 or more?
    
    private let awsProfileName: String
    private let awsRegion = SotoCore.Region.eucentral1
    private let awsClient: AWSClient
    //private let s3: S3
    private let sts: STS
    private let iam: IAM
    private let lambda: Lambda
    private let apiGateway: ApiGatewayV2
    
    private let logger = Logger(label: "de.lukaskollmer.ApodiniLambda.AWSIntegration")
    
    
    init(
        awsProfileName: String,
        deploymentStructure: DeployedSystemStructure,
        openApiDocument: OpenAPI.Document,
        tmpDirUrl: URL,
        lambdaExecutableUrl: URL,
        lambdaSharedObjectFilesUrl: URL
    ) {
        self.awsProfileName = awsProfileName
        self.deploymentStructure = deploymentStructure
        self.openApiDocument = openApiDocument
        self.tmpDirUrl = tmpDirUrl
        self.lambdaSharedObjectFilesUrl = lambdaSharedObjectFilesUrl
        self.lambdaExecutableUrl = lambdaExecutableUrl
        awsClient = AWSClient(credentialProvider: .configFile(profile: awsProfileName), httpClientProvider: .createNew)
        sts = STS(client: awsClient, region: awsRegion)
        iam = IAM(client: awsClient)
        lambda = Lambda(client: awsClient, region: awsRegion, timeout: nil)
        apiGateway = ApiGatewayV2(client: awsClient, region: awsRegion)
    }
    
    
    deinit {
        logger.trace("-[\(Self.self) \(#function)]")
        try! awsClient.syncShutdown()
    }
    
    
    
    enum ApiGatewayIdInput {
        case createNew
        case useExisting(String)
    }
    
    
    /// - parameter s3BucketName: name of the S3 bucket the function should be uploaded to
    /// - parameter s3ObjectFolderKey: key (ie path) of the folder into which the function should be uploaded
    func apply(s3BucketName: String, s3ObjectFolderKey: String, dstApiGateway apiGatewayIdInput: ApiGatewayIdInput) throws {
        logger.trace("-[\(Self.self) \(#function)]")
        
        let accountId = try sts.getCallerIdentity(STS.GetCallerIdentityRequest()).wait().account!
        
        let apiGatewayApiId: String = try {
            switch apiGatewayIdInput {
            case .useExisting(let id):
                return id
            case .createNew:
                return try apiGateway.createApi(ApiGatewayV2.CreateApiRequest(
                    name: "apodini-tmp-api", // doesnt matter will be replaced when importing the openapi spec
                    protocolType: .http
                )).wait().apiId!
            }
        }()
        
        logger.notice("Fetching list of all lambda functions in AWS account")
        let allFunctionsResponse = try lambda.listFunctions(Lambda.ListFunctionsRequest()).wait()
        
        if allFunctionsResponse.nextMarker != nil {
            logger.warning("nextMarker not nil!!!")
        }
        
        let allFunctions = allFunctionsResponse.functions ?? []
        logger.notice("#functions: \(allFunctions.count) \(allFunctions.map(\.functionArn!))")

        
        // Delete old functions
        do {
            let functionsToBeDeleted = allFunctions.filter { $0.functionName!.hasPrefix("apodini-lambda") }
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
        
        
        let executionRole = try { () -> IAM.Role in
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
            
            
            
//            logger.notice("Attaching AWSLambdaBasicExecutionRole policy to role")
//            try iam.attachRolePolicy(
//                IAM.AttachRolePolicyRequest(
//                    policyArn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
//                    roleName: role.roleName
//                )
//            ).wait()
            return role
        }()
        
        
        var nodeToLambdaFunctionMapping: [DeployedSystemStructure.Node.ID: Lambda.FunctionConfiguration] = [:]
        
        
        logger.notice("Creating lambda functions for nodes in the web service deployment structure")
        for node in deploymentStructure.nodes {
            logger.notice("Creating lambda function for node w/ id \(node.id) (handlers: \(node.exportedEndpoints.map { ($0.httpMethod, $0.absolutePath) })")
            let lambdaName = "apodini-lambda-\(node.id)"
            
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
//                logger.notice("- adding shared object file \(sharedObjectFileUrl.lastPathComponent)")
//                try FM.copyItem(
//                    at: sharedObjectFileUrl,
//                    to: lambdaPackageTmpDir.appendingPathComponent(sharedObjectFileUrl.lastPathComponent, isDirectory: false)
//                )
                try addToLambdaPackage(sharedObjectFileUrl)
            }
            
            try addToLambdaPackage(lambdaExecutableUrl)
            
            let launchInfoFileUrl = lambdaPackageTmpDir.appendingPathComponent("launchInfo.json", isDirectory: false)
            logger.notice("- adding launchInfo.json")
            try deploymentStructure.withCurrentInstanceNodeId(node.id).writeTo(url: launchInfoFileUrl)
            
            do {
                // create & add bootstrap file
                logger.notice("- adding bootstrap")
                let bootstrapFileContents = """
                #!/bin/bash
                ./\(lambdaExecutableUrl.lastPathComponent) \(WellKnownCLIArguments.launchWebServiceInstanceWithCustomConfig) ./\(launchInfoFileUrl.lastPathComponent)
                """
                let bootstrapFileUrl = lambdaPackageTmpDir.appendingPathComponent("bootstrap", isDirectory: false)
                try bootstrapFileContents.write(to: bootstrapFileUrl, atomically: true, encoding: .utf8)
                
                try Task(
                    executableUrl: chmodBin,
                    arguments: ["+x", bootstrapFileUrl.path],
                    captureOutput: false,
                    launchInCurrentProcessGroup: true
                ).launchSyncAndAssertSuccess()
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
            
            //let s3ObjectKey = [s3ObjectFolderKey, lambdaExecutableUrl.lastPathComponent].joined(separator: "/")
            let s3ObjectKey = "/\(s3ObjectFolderKey)/\(lambdaExecutableUrl.lastPathComponent).zip"
            
            try Task(
                executableUrl: awsCliBin,
                //arguments: ["s3", "cp", ""],
                arguments: [
                    "--profile", awsProfileName,
                    "s3", "cp",
                    "\(lambdaPackageTmpDir.path)/\(zipFilename)",
                    //"s3://\(s3BucketName)/\(s3ObjectFolderKey)/\(lambdaExecutableUrl.lastPathComponent).zip"
                    "s3://\(s3BucketName)/\(s3ObjectKey)"
                ],
                captureOutput: false,
                launchInCurrentProcessGroup: true
            ).launchSyncAndAssertSuccess()
            
            //let launchConfig = try deploymentStructure.withCurrentInstanceNodeId(node.id).writeTo(url: <#T##URL#>)
            
            
            let functionConfig: Lambda.FunctionConfiguration
            
            if let function = allFunctions.first(where: { $0.functionName == lambdaName }) {
                logger.notice("Found existing lambda function w/ matching name. Updating code")
                let updateCodeRequest = Lambda.UpdateFunctionCodeRequest(
                    functionName: function.functionName!,
                    s3Bucket: s3BucketName,
                    s3Key: s3ObjectKey
                )
                functionConfig = try lambda.updateFunctionCode(updateCodeRequest).wait()
            } else {
                logger.notice("Creating new lambda function")
                let createFunctionRequest = Lambda.CreateFunctionRequest(
                    code: .init(s3Bucket: s3BucketName, s3Key: s3ObjectKey),
                    description: "Apodini-created lambda function",
                    environment: nil, //.init(variables: [String : String]?.none), // TODO?
                    functionName: lambdaName,
                    handler: "apodini.main", // doesn;t actually matter
                    memorySize: nil, // TODO
                    packageType: .zip,
                    publish: true,
                    role: executionRole.arn,
                    runtime: .providedAl2,
                    tags: nil, // [String : String]?.none,
                    timeout: nil // default is 3?
                )
                functionConfig = try lambda.createFunction(createFunctionRequest).wait()
                logger.notice("functionConfig: \(functionConfig)")
            }
            
            nodeToLambdaFunctionMapping[node.id] = functionConfig
            
            let addPermissionsResponse = try lambda.addPermission(Lambda.AddPermissionRequest(
                action: "lambda:InvokeFunction",
                functionName: functionConfig.functionName!,
                principal: "apigateway.amazonaws.com",
                sourceArn: "arn:aws:execute-api:\(awsRegion.rawValue):\(accountId):\(apiGatewayApiId)/*/*/*", // /*/*/v1
                statementId: UUID().uuidString.lowercased()
            )).wait()
            print("addPermissionsResponse", addPermissionsResponse)
        }
        
        
        //
        // API GATEWAY
        //
        
        var apiGatewayImportDef = openApiDocument
        //OpenAPI.Document(openAPIVersion: <#T##OpenAPI.Document.Version#>, info: <#T##OpenAPI.Document.Info#>, servers: <#T##[OpenAPI.Server]#>, paths: <#T##OpenAPI.PathItem.Map#>, components: <#T##OpenAPI.Components#>, security: <#T##[OpenAPI.SecurityRequirement]#>, tags: <#T##[OpenAPI.Tag]?#>, externalDocs: <#T##OpenAPI.ExternalDocumentation?#>, vendorExtensions: <#T##[String : AnyCodable]#>)
        
        apiGatewayImportDef.vendorExtensions["x-amazon-apigateway-importexport-version"] = "1.0"
        
        apiGatewayImportDef.servers = [
            OpenAPI.Server(
                url: URL(string: "https://\(apiGatewayApiId).execute-api.\(awsRegion.rawValue).amazonaws.com/")!,
                description: nil,
                variables: OrderedDictionary<String, OpenAPI.Server.Variable>(),
                vendorExtensions: Dictionary<String, AnyCodable>()
            )
        ]
        
        apiGatewayImportDef.paths = apiGatewayImportDef.paths.mapValues { (pathItem: OpenAPI.PathItem) -> OpenAPI.PathItem in
            var pathItem = pathItem
            for endpoint in pathItem.endpoints {
                var operation = endpoint.operation
                let handlerId = operation.vendorExtensions["x-handlerId"]!.value as! String
                let nodes = deploymentStructure.nodesExportingEndpoint(withHandlerId: handlerId)
                precondition(nodes.count == 1)
                let nodeId = nodes.first!.id
                let lambdaFunctionConfig = nodeToLambdaFunctionMapping[nodeId]!
                operation.vendorExtensions["x-amazon-apigateway-integration"] = [
                    "type": "aws_proxy",
                    "httpMethod": "POST",
                    "connectionType": "INTERNET",
                    "uri": "arn:aws:apigateway:\(awsRegion.rawValue):lambda:path/2015-03-31/functions/\(lambdaFunctionConfig.functionArn!)/invocations",
                    //"uri": lambdaFunctionConfig.functionArn!,
                    //"credentials": lambdaFunctionConfig.role!,
                    "payloadFormatVersion": "2.0"
                ]
                
                // arn:aws:lambda:eu-central-1:873474603240:function:apodini-lambda-0
                //arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:012345678901:function:HelloWorld/invocations
                pathItem.set(operation: operation, for: endpoint.method)
            }
            return pathItem
        }
        
        let openApiDefPath = self.tmpDirUrl.appendingPathComponent("openapi.json", isDirectory: false)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        try encoder.encode(apiGatewayImportDef).write(to: openApiDefPath)
        
        let reimportRequest = ApiGatewayV2.ReimportApiRequest(
            apiId: apiGatewayApiId,
            basepath: nil, // TODO?
            body: String(data: try Data(contentsOf: openApiDefPath), encoding: .utf8)!,
            //body: "file://\(openApiDefPath.path)",
            failOnWarnings: true // Too strict?
        )
        //print("reimportReq", reimportRequest)
        
        let res = try apiGateway.reimportApi(reimportRequest).wait()
        print("uff", res)
    }
}



extension Optional {
    func lk_or(_ value: @autoclosure () -> Wrapped) -> Wrapped {
        self ?? value()
    }
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
