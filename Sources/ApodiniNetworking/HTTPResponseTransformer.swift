//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniExtension
import ApodiniUtils
import ApodiniHTTPProtocol
import ApodiniNetworkingHTTPSupport


public struct HTTPResponseTransformer<H: Handler>: ResultTransformer {
    private let encoder: AnyEncoder
    
    public init(_ encoder: AnyEncoder) {
        self.encoder = encoder
    }
    
    public func transform(input: Apodini.Response<H.Response.Content>) throws -> HTTPResponse {
        let response = HTTPResponse(
            version: .http1_1, // placeholder, actual value will be set below
            status: input.responseStatus,
            headers: HTTPHeaders(input.information)
        )
        var body = ByteBuffer()
        if let content = input.content {
            try encoder.encode(content, to: &body, headers: &response.headers)
        }
        response.bodyStorage = .buffer(body)

        if let httpVersion = input.information[HTTPRequest.InformationEntryHTTPVersion.Key.shared] {
            response.version = httpVersion
        } else {
            response.httpServerShouldIgnoreHTTPVersionAndInsteadMatchRequest = true
        }
        return response
    }
    
    public func handle(error: ApodiniError) -> ErrorHandlingStrategy<HTTPResponse, ApodiniError> {
        .abort(error)
    }
}


public struct HTTPBlobResponseTransformer: ResultTransformer {
    public init() { }
    
    public func transform(input: Apodini.Response<Blob>) -> HTTPResponse {
        var body: ByteBuffer
        var information = input.information
        if let content = input.content {
            body = content.byteBuffer
            if let mediaType = content.type {
                information = information.merge(with: [
                    AnyHTTPInformation(key: "Content-Type", rawValue: mediaType.encodeToHTTPHeaderFieldValue())
                ])
            }
        } else {
            body = .init()
        }
        let response = HTTPResponse(
            version: .http1_1, // placeholder, actual value will be set below
            status: input.responseStatus,
            headers: HTTPHeaders(information),
            bodyStorage: .buffer(body)
        )
        if let httpVersion = input.information[HTTPRequest.InformationEntryHTTPVersion.Key.shared] {
            response.version = httpVersion
        } else {
            response.httpServerShouldIgnoreHTTPVersionAndInsteadMatchRequest = true
        }
        return response
    }
    
    public func handle(error: ApodiniError) -> ErrorHandlingStrategy<HTTPResponse, ApodiniError> {
        .abort(error)
    }
}


private extension Apodini.Response {
    var responseStatus: HTTPResponseStatus {
        switch self.status {
        case let .some(status):
            return HTTPResponseStatus(status)
        case .none:
            if self.content == nil {
                return .noContent
            } else {
                return .ok
            }
        }
    }
}
