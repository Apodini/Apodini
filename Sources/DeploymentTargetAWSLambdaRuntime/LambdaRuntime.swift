//
//  LambdaRuntime.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-18.
//

import Foundation
import Vapor
import ApodiniDeployRuntimeSupport
import DeploymentTargetAWSLambdaCommon
import VaporAWSLambdaRuntime
import SotoLambda




public class LambdaRuntime: DeploymentProviderRuntimeSupport {
    public static let deploymentProviderId = LambdaDeploymentProviderId
    
    private let deploymentStructure: DeployedSystemStructure
    private let lambdaDeploymentContext: LambdaDeployedSystemContext
    
    private var app: Vapor.Application!
    private var awsClient: AWSClient!
    private var lambda: Lambda!
    
    
    public required init(deployedSystemStructure: DeployedSystemStructure) throws {
        self.deploymentStructure = deployedSystemStructure
        guard let lambdaDeploymentContext = deploymentStructure.readUserInfo(as: LambdaDeployedSystemContext.self) else {
            throw NSError(domain: Self.deploymentProviderId.rawValue, code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Unable to read userInfo object"
            ])
        }
        self.lambdaDeploymentContext = lambdaDeploymentContext
    }
    
    
    deinit {
        try! awsClient.syncShutdown()
    }
    
    
    public func configure(_ app: Vapor.Application) throws {
        print("-[\(Self.self) \(#function)] env", ProcessInfo.processInfo.environment)
        self.app = app
        app.servers.use(.lambda)
        app.http.server.configuration.address = .hostname(lambdaDeploymentContext.apiGatewayHostname, port: 443)
        
        self.awsClient = AWSClient(credentialProvider: .environment, httpClientProvider: .createNewWithEventLoopGroup(app.eventLoopGroup))
        self.lambda = SotoLambda.Lambda(client: awsClient, region: .eucentral1)
    }
    
    
    public func handleRemoteHandlerInvocation<Response: Decodable>(
        withId handlerId: String,
        inTargetNode targetNode: DeployedSystemConfiguration.Node,
        responseType: Response.Type,
        parameters: [HandlerInvocationParameter]
    ) throws -> RemoteHandlerInvocationRequestResponse<Response> {
        return .invokeDefault(url: URL(string: "https://\(lambdaDeploymentContext.apiGatewayHostname)")!)
    }
    
//    public func invokeRemoteHandler<Response : Decodable>(
//        withId handlerId: String,
//        inTargetNode targetNode: DeployedSystemConfiguration.Node,
//        responseType: Response.Type,
//        parameters: [HandlerInvocationParameter]
//    ) throws -> EventLoopFuture<Response> {
//        //print(#function, handlerId, targetNode)
//        print(#function)
//        print("- handlerId: \(handlerId)")
//        print("- targetNode: \(targetNode)")
//        print("- responseType: \(responseType)")
//        print("- parameters: \(parameters)")
//
//        let dstFunctionArn = "arn:aws:lambda:eu-central-1:873474603240:function:apodini-lambda-RandomNumberGenerator-main"
//
////        let url = Vapor.URI(
////            scheme: .https,
////            host: "lambda.eu-central-1.amazonaws.com",
////            path: "/2015-03-31/functions/\(dstFunctionArn)/invocations",
////            query: nil// Qualifier=Qualifier,
////        )
//
////        let client = AWSClient(
////            credentialProvider: .environment,
////            httpClientProvider: .createNewWithEventLoopGroup(app.eventLoopGroup)
////        )
//        //let apiGateway = ApiGatewayV2(client: client, region: .eucentral1)
//
//        return lambda.invoke(SotoLambda.Lambda.InvocationRequest(
//            clientContext: "CLIENTCONTEXT BABYYYYY",
//            functionName: dstFunctionArn,
//            invocationType: .requestresponse,
//            logType: .tail,
//            payload: nil, // TODO
//            qualifier: nil
//        ))
//        .map { (lambdaInvocationResponse: SotoLambda.Lambda.InvocationResponse) -> Response in
//            print("lambdaInvocationResponse", lambdaInvocationResponse)
//            fatalError("lambdaInvocationResponse \(lambdaInvocationResponse)")
//        }
//
////        return self.app.client.post(
////            url,
////            headers: [
////                "X-Amz-Invocation-Type": "RequestResponse",
////                "X-Amz-Log-Type": "Tail",
////                "X-Amz-Client-Context": "CLIENTCONTEXT BABYYYYY"
////            ]) { request in
////            print("request: \(request)")
////        }
////        .map { (response: Vapor.ClientResponse) -> Response in
////            print("clientResponse", response)
////            fatalError("CR \(response)")
////        }
////
////        throw NSError(domain: "ugh", code: 0, userInfo: nil)
//    }
}
