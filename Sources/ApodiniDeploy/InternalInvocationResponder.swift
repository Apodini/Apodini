//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-24.
//

import Foundation
import NIO
import NIOHTTP1
@_implementationOnly import Vapor
import Apodini


struct InternalInvocationResponder<H: Handler>: Vapor.Responder {
    unowned let RHIIE: ApodiniDeployInterfaceExporter
    let endpoint: Endpoint<H>
    
    func respond(to vaporRequest: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        // Note: this function _must always_ return non-failed futures!!! (?)
        do {
            let request = try vaporRequest.content.decode(Request.self)
            for param in request.parameters {
                print("param: \(param)")
            }
            return endpoint._invoke(
                withRequest: ApodiniDeployInterfaceExporter.ExporterRequest(
                    encodedParameters: request.parameters.map { param -> (String, Data) in
                        return (param.stableIdentity, param.value)
                    }
                ),
                RHIIE: RHIIE,
                on: vaporRequest.eventLoop
            ).map { (handlerResponse: H.Response.Content) -> Vapor.Response in
                // TODO how should this handle an error here?
                let vaporResponse = Vapor.Response(status: .ok)
                try! vaporResponse.content.encode(
                    Response(
                        statusCode: .ok,
                        responseData: try! JSONEncoder().encode(handlerResponse)
                    ),
                    using: JSONEncoder()
                )
                return vaporResponse
            }
        } catch {
            let vaporResponse = Vapor.Response(status: .ok)
            try! vaporResponse.content.encode(
                Response(
                    statusCode: .internalServerError,
                    responseData: try! JSONEncoder().encode(error.localizedDescription) // TODO or just do str.data???
                ),
                using: JSONEncoder()
            )
            return vaporRequest.eventLoop.makeSucceededFuture(vaporResponse)
        }
    }
}


extension InternalInvocationResponder {
    struct Request: Codable {
        struct EncodedParameter: Codable {
            let stableIdentity: String
            let value: Data // TODO
        }
        let parameters: [EncodedParameter]
    }
    
    
    struct Response: Codable {
        let statusCode: NIOHTTP1.HTTPResponseStatus
        let responseData: Data //H.Response.Content
    }
}
