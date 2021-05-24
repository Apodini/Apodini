//
//  InternalInvocationResponder.swift
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
    unowned let internalInterfaceExporter: ApodiniDeployInterfaceExporter
    let endpoint: Endpoint<H>
    
    func respond(to vaporRequest: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        // Note: this function _must always_ return non-failed futures!!!
        // Otherwise the caller would not be able to differentiate between errors
        // caused by e.g. a bad connection, and errors caused by e.g. the invoked handler
        let request: Request
        do {
            request = try vaporRequest.content.decode(Request.self)
        } catch {
            let vaporResponse = Vapor.Response(status: .internalServerError)
            do {
                try vaporResponse.content.encode(
                    Response(
                        status: .internalError,
                        encodedData: try JSONEncoder().encode(error.localizedDescription)
                    ),
                    using: JSONEncoder()
                )
            } catch {
                vaporResponse.status = .internalServerError
            }
            return vaporRequest.eventLoop.next().makeSucceededFuture(vaporResponse)
        }
        return endpoint.invokeImp(
            withRequest: ApodiniDeployInterfaceExporter.ExporterRequest(
                encodedArguments: request.parameters.map { param -> (String, Data) in
                    (param.stableIdentity, param.encodedValue)
                }
            ),
            internalInterfaceExporter: internalInterfaceExporter,
            on: vaporRequest.eventLoop
        )
        .map { (handlerResponse: H.Response.Content) -> Vapor.Response in
            let vaporResponse = Vapor.Response(status: .ok)
            let encodedHandlerResponse: Data
            do {
                do {
                    encodedHandlerResponse = try JSONEncoder().encode(handlerResponse)
                } catch {
                    // We end up here if there was an error encoding the handler's response
                    try vaporResponse.content.encode(
                        Response(status: .internalError, encodedData: try error.localizedDescription.encodeToJSON()),
                        using: JSONEncoder()
                    )
                    return vaporResponse
                }
                try vaporResponse.content.encode(
                    Response(status: .success, encodedData: encodedHandlerResponse),
                    using: JSONEncoder()
                )
            } catch {
                vaporResponse.status = .internalServerError
            }
            return vaporResponse
        }
        .flatMapErrorThrowing { (handlerError: Error) -> Vapor.Response in
            // We end up here if the handler threw an error
            let vaporResponse = Vapor.Response(status: .ok)
            do {
                try vaporResponse.content.encode(
                    Response(status: .handlerError, encodedData: try JSONEncoder().encode(handlerError.localizedDescription)),
                    using: JSONEncoder()
                )
            } catch {
                vaporResponse.status = .internalServerError
            }
            return vaporResponse
        }
    }
}


extension InternalInvocationResponder {
    struct Request: Codable {
        struct EncodedParameter: Codable {
            let stableIdentity: String
            let encodedValue: Data
        }
        let parameters: [EncodedParameter]
    }
    
    
    enum ResponseStatus: String, Codable {
        // The handler returned without throwing an error
        case success
        // The handler threw an error
        case handlerError
        // The handler returned w/out an error, but there was an
        // internal error when handling the handler's response
        case internalError
    }
    
    struct Response: Codable {
        let status: ResponseStatus
        let encodedData: Data
    }
}
