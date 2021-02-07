//
//  ProxyServer.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-02.
//

import Foundation
import Vapor
import ApodiniDeployBuildSupport
import DeploymentTargetLocalhostCommon
import Logging


private let proxyServerLogger = Logger(label: "DeploymentTargetLocalhost.ProxyServer")


class ProxyServer {
    let webServiceStructure: WebServiceStructure
    let deployedSystem: DeployedSystemStructure
    
    fileprivate let app: Application
    
    init(webServiceStructure: WebServiceStructure, deployedSystem: DeployedSystemStructure) throws {
        self.webServiceStructure = webServiceStructure
        self.deployedSystem = deployedSystem
        
        let environmentName = try Vapor.Environment.detect().name
        var env = Vapor.Environment(name: environmentName, arguments: ["vapor"])
        try LoggingSystem.bootstrap(from: &env)
        self.app = Application(env)
        
        for endpoint in webServiceStructure.endpoints {
            let route = Route(
                method: HTTPMethod(rawValue: endpoint.httpMethod),
                path: endpoint.absolutePath.pathComponents, //[.catchall],
                responder: ProxyRequestResponder(proxyServer: self, endpoint: endpoint),
                requestType: Vapor.Request.self,
                responseType: EventLoopFuture<ClientResponse>.self
            )
            app.add(route)
            print("ROUTE", route)
        }
    }
    
    
    /// Start the proxy
    func run(port: Int) throws {
        defer {
            proxyServerLogger.notice("shutdown")
            app.shutdown()
        }
        app.http.server.configuration.port = port
        try app.run()
    }
}



private struct ProxyRequestResponder: Vapor.Responder {
    let proxyServer: ProxyServer
    let endpoint: ExportedEndpoint
    
    func respond(to request: Request) -> EventLoopFuture<Response> {
        guard let targetNode = proxyServer.deployedSystem.nodeExportingEndpoint(withHandlerId: endpoint.handlerId) else {
            return request.eventLoop.makeFailedFuture(NSError(domain: "sorry", code: 0, userInfo: [:]))
        }
        let targetNodeLocalhostData = targetNode.readUserInfo(as: LocalhostLaunchInfo.self)!
        let url = Vapor.URI(
            scheme: "http",
            host: "127.0.0.1",
            port: targetNodeLocalhostData.port,
            path: request.url.path,
            query: request.url.query,
            fragment: request.url.fragment
        )
        proxyServerLogger.notice("forwarding request to '\(url)'")
        // TODO can we reuse the headers just like that?
        let clientResponseFuture = request.client.send(request.method, headers: request.headers, to: url) { (clientReq: inout ClientRequest) in
            //clientReq.body = request.body.data
            clientReq.body = request.body.data
        }
        return clientResponseFuture.flatMap { clientResponse in
            // Note: For some reason, Vapor will duplicate some header fields when sending this response back to the client.
            // The ones i noticed were `date` and `connection`, but that's probably not the full list.
            let ignoredHeaderFields: [HTTPHeaders.Name] = [.date, .connection]
            let response = Response(
                status: clientResponse.status,
                //version, // `ClientResponse` doesn't have a version, we could use the default (what we're doing) or return the initial request's version
                headers: HTTPHeaders(clientResponse.headers.filter { !ignoredHeaderFields.contains(HTTPHeaders.Name($0.name)) }),
                body: clientResponse.body.map { Response.Body.init(buffer: $0) } ?? .empty
            )
            return proxyServer.app.eventLoopGroup.next().makeSucceededFuture(response)
        }
    }
}
