//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import NIO
import NIOHTTP1
import Apodini
import ApodiniNetworking

// TODO transition this to ApodiniNetworking

struct InternalInvocationResponder<H: Handler> {//: Vapor.Responder { // TODO make this a LKHTTPResponder in its own riught?
    unowned let internalInterfaceExporter: ApodiniDeployInterfaceExporter
    let endpoint: Endpoint<H>
    
    func respond(to httpRequest: LKHTTPRequest) -> LKHTTPResponseConvertible {
        // Note: this function _must always_ return non-failed futures!!!
        // Otherwise the caller would not be able to differentiate between errors
        // caused by e.g. a bad connection, and errors caused by e.g. the invoked handler
        let request: Request
        do {
            //request = try vaporRequest.content.decode(Request.self)
            //request = try httpRequest.decodeBody(as: Request.self)
            request = try httpRequest.bodyStorage.getFullBodyData(decodedAs: Request.self)
        } catch {
            //let vaporResponse = Vapor.Response(status: .internalServerError)
            let httpResponse = LKHTTPResponse(version: httpRequest.version, status: .internalServerError, headers: [:])
            do {
//                try vaporResponse.content.encode(
//                    Response(
//                        status: .internalError,
//                        encodedData: try JSONEncoder().encode(error.localizedDescription)
//                    ),
//                    using: JSONEncoder()
//                )
                //try httpResponse.encodeBody(Response(status: .internalError, encodedData: try JSONEncoder().encode(error.localizedDescription)))
                try httpResponse.bodyStorage.write(encoding: Response(
                    status: .internalError,
                    encodedData: try JSONEncoder().encode(error.localizedDescription) // TODO why pipe this through the JSON encoder?
                ))
            } catch {
                httpResponse.status = .internalServerError
            }
            //return vaporRequest.eventLoop.next().makeSucceededFuture(vaporResponse)
            return httpResponse
        }
        return endpoint.invokeImp(
            withRequest: ApodiniDeployInterfaceExporter.ExporterRequest(
                encodedArguments: request.parameters.map { param -> (String, Data) in
                    (param.stableIdentity, param.encodedValue)
                }
            ),
            internalInterfaceExporter: internalInterfaceExporter,
            on: httpRequest.eventLoop
        )
        .map { (handlerResponse: H.Response.Content) -> LKHTTPResponse in
            let httpResponse = LKHTTPResponse(version: httpRequest.version, status: .ok, headers: [:])
            let encodedHandlerResponse: Data
            do {
                do {
                    encodedHandlerResponse = try JSONEncoder().encode(handlerResponse)
                } catch {
                    // We end up here if there was an error encoding the handler's response
                    //try httpResponse.encodeBody(Response(status: .internalError, encodedData: try error.localizedDescription.encodeToJSON()))
                    try httpResponse.bodyStorage.write(encoding: Response(status: .internalError, encodedData: try error.localizedDescription.encodeToJSON()))
//                    try vaporResponse.content.encode(
//                        Response(status: .internalError, encodedData: try error.localizedDescription.encodeToJSON()),
//                        using: JSONEncoder()
//                    )
                    return httpResponse
                }
//                try vaporResponse.content.encode(
//                    Response(status: .success, encodedData: encodedHandlerResponse),
//                    using: JSONEncoder()
//                )
                //try httpResponse.encodeBody(Response(status: .success, encodedData: encodedHandlerResponse))
                try httpResponse.bodyStorage.write(encoding: Response(status: .success, encodedData: encodedHandlerResponse))
            } catch {
                httpResponse.status = .internalServerError
            }
            return httpResponse
        }
        .flatMapErrorThrowing { (handlerError: Error) -> LKHTTPResponse in
            // We end up here if the handler threw an error
            let httpResponse = LKHTTPResponse(version: httpRequest.version, status: .ok, headers: [:])
            do {
                //try httpResponse.encodeBody(Response(status: .handlerError, encodedData: try JSONEncoder().encode(handlerError.localizedDescription)))
                try httpResponse.bodyStorage.write(encoding: Response(
                    status: .handlerError,
                    encodedData: try JSONEncoder().encode(handlerError.localizedDescription) // ^^ same as above
                ))
//                try vaporResponse.content.encode(
//                    Response(status: .handlerError, encodedData: try JSONEncoder().encode(handlerError.localizedDescription)),
//                    using: JSONEncoder()
//                )
            } catch {
                httpResponse.status = .internalServerError
            }
            return httpResponse
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
