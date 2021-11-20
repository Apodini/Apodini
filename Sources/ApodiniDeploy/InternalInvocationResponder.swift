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
import ApodiniUtils
import Logging


struct InternalInvocationResponder<H: Handler>: HTTPResponder {
    unowned let internalInterfaceExporter: ApodiniDeployInterfaceExporter
    let endpoint: Endpoint<H>
    
    func respond(to httpRequest: HTTPRequest) -> HTTPResponseConvertible {
        // Note: this function _must always_ return non-failed futures!!!
        // Otherwise the caller would not be able to differentiate between errors
        // caused by e.g. a bad connection, and errors caused by e.g. the invoked handler
        let request: Request
        do {
            request = try httpRequest.bodyStorage.getFullBodyData(decodedAs: Request.self)
        } catch {
            let httpResponse = HTTPResponse(version: httpRequest.version, status: .internalServerError, headers: [:])
            do {
                try httpResponse.bodyStorage.write(encoding: Response(
                    status: .internalError,
                    encodedData: try JSONEncoder().encode(error.localizedDescription)
                ))
            } catch {
                httpResponse.status = .internalServerError
            }
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
        .map { (handlerResponse: H.Response.Content) -> HTTPResponse in
            let httpResponse = HTTPResponse(version: httpRequest.version, status: .ok, headers: [:])
            let encodedHandlerResponse: Data
            do {
                do {
                    encodedHandlerResponse = try JSONEncoder().encode(handlerResponse)
                } catch {
                    // We end up here if there was an error encoding the handler's response
                    try httpResponse.bodyStorage.write(
                        encoding: Response(status: .internalError, encodedData: try error.localizedDescription.encodeToJSON())
                    )
                    return httpResponse
                }
                try httpResponse.bodyStorage.write(encoding: Response(status: .success, encodedData: encodedHandlerResponse))
            } catch {
                httpResponse.status = .internalServerError
            }
            return httpResponse
        }
        .flatMapErrorThrowing { (handlerError: Error) -> HTTPResponse in
            // We end up here if the handler threw an error
            let httpResponse = HTTPResponse(version: httpRequest.version, status: .ok, headers: [:])
            do {
                try httpResponse.bodyStorage.write(encoding: Response(
                    status: .handlerError,
                    encodedData: try JSONEncoder().encode(handlerError.localizedDescription)
                ))
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
