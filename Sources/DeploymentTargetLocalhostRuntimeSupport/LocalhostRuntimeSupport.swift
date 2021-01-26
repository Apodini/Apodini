//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
import ApodiniDeployRuntimeSupport
import Vapor
import DeploymentTargetLocalhostCommon


enum TmpError: Error {
    case unspecified
    case other(String)
}



struct WrappedRESTResponse<T: Decodable>: Decodable {
    let data: T
}


extension Vapor.URLEncodedFormEncoder: AnyEncoder {
    public func encode<T>(_ value: T) throws -> Data where T : Encodable {
        let encodedString: String = try self.encode(value)
        if let data = encodedString.data(using: .utf8) {
            return data
        } else {
            throw TmpError.other("ugh")
        }
    }
}





public class LocalhostRuntimeSupport: DeploymentProviderRuntimeSupport {
    public static let deploymentProviderId = LocalhostDeploymentProviderId
    
    private let deployedSystemStructure: DeployedSystemConfiguration
    private let currentNodeCustomLaunchInfo: LocalhostLaunchInfo
    
    private var app: Vapor.Application? // TODO remove this and instead add the app as a parameter to -invokeRemoteHandler?
    
    public required init(deployedSystemStructure: DeployedSystemConfiguration) {
        self.deployedSystemStructure = deployedSystemStructure
        self.currentNodeCustomLaunchInfo = deployedSystemStructure.currentInstanceNode.readUserInfo(as: LocalhostLaunchInfo.self)!
    }
    
    
    public func configure(_ app: Vapor.Application) throws {
        self.app = app
        app.http.server.configuration.port = currentNodeCustomLaunchInfo.port
    }
    
    
    public func handleRemoteHandlerInvocation<Response: Decodable>(
        withId handlerId: String,
        inTargetNode targetNode: DeployedSystemConfiguration.Node,
        responseType: Response.Type,
        parameters: [HandlerInvocationParameter]
    ) throws -> RemoteHandlerInvocationRequestResponse<Response> {
        let LLI = targetNode.readUserInfo(as: LocalhostLaunchInfo.self)!
        return .invokeDefault(url: URL(string: "http://127.0.0.1:\(LLI.port)")!)
    }
    
//    public func invokeRemoteHandler<Response: Decodable>(
//        withId handlerId: String,
//        inTargetNode targetNode: DeployedSystemConfiguration.Node,
//        responseType: Response.Type,
//        parameters: [HandlerInvocationParameter]
//    ) throws -> EventLoopFuture<Response> {
//        guard let app = app else {
//            throw TmpError.unspecified
//        }
//        let LLI = targetNode.readUserInfo(as: LocalhostLaunchInfo.self)!
//        let endpoint = targetNode.exportedEndpoints.first { $0.handlerIdRawValue == handlerId }!
//        let url = Vapor.URI(
//            scheme: "http",
//            host: "127.0.0.1",
//            port: LLI.port,
//            path: endpoint.absolutePath,
//            query: try parameters.reduce(into: "") { (query: inout String, param) in
//                switch param.restParameterType {
//                case .body, .path:
//                    return
//                case .query:
//                    // Note: this is in fact pretty bad, bc what we're doing is were making the URLEncodedFormEncoder (which returns a String)
//                    // conform to AnyEncoder (so that we can pass it to -encodeValue) by converting this String into Data,
//                    // and then converting this Data object back into a string.
//                    // Another issue here is that, if the param value is a non-primitive Codable type (eg a struct) its members
//                    // will get "flattened" into url query params, which will mess up the rest of the query string.
//                    // Example: we have an instance of a User struct, which we're passing w/ the param name `user`.
//                    // We'd probably expect something like `?user=<encoded user>` but Vapor's URLEncodedFormEncoder will encode the User object
//                    // into `name=<>&age=<>`, if we now try to concat that onto `&paramName=<>` it'll make no sense whatsoever.
//                    // Don't think this can easily be fixed, since this issue isn't really caused by this specific use case here, but rather by
//                    // allowing the possibility of complex types in query params in the first place.
//                    guard let value = String(data: try param.encodeValue(using: URLEncodedFormEncoder()), encoding: .utf8) else {
//                        fatalError("Unable to encode query string parameter '\(param.name)'")
//                    }
//                    if !query.isEmpty && !query.hasSuffix("&") {
//                        query += "&"
//                    }
//                    query += "\(param.name)=\(value)"
//                }
//            },
//            fragment: nil
//        )
//
//        return app.client.send(
//            HTTPMethod(rawValue: endpoint.httpMethod),
//            headers: HTTPHeaders(),
//            to: url
//        ) { (req: inout ClientRequest) in
//            precondition(
//                parameters.lk_count(where: { $0.restParameterType == .body }) <= 1,
//                "At most one parameter can be encoded into the request body"
//            )
//            guard let bodyParamIdx = parameters.lk_firstIndex(from: parameters.startIndex, where: { $0.restParameterType == .body }) else {
//                return
//            }
//            let bodyParam = parameters[bodyParamIdx]
//            try bodyParam.encodeValue(into: &req.content, using: JSONEncoder())
//        }.flatMapThrowing { (response: ClientResponse) -> Response in
//            try response.content.decode(WrappedRESTResponse<Response>.self).data
//        }
//    }
}
