//
//  ResponseTransformers.swift
//  
//
//  Created by Max Obermeier on 30.06.21.
//

import Apodini
import ApodiniExtension
import Vapor

public struct VaporResponseTransformer<H: Handler>: ResultTransformer {
    private let encoder: AnyEncoder
    
    public init(_ encoder: AnyEncoder) {
        self.encoder = encoder
    }
    
    public func transform(input: Apodini.Response<H.Response.Content>) throws -> Vapor.Response {
        var body: Vapor.Response.Body
        
        if let content = input.content {
            body = Vapor.Response.Body(data: try encoder.encode(content))
        } else {
            body = Vapor.Response.Body()
        }
        
        return Vapor.Response(status: input.responseStatus,
                              headers: HTTPHeaders(input.information),
                              body: body)
    }
    
    public func handle(error: ApodiniError) -> ErrorHandlingStrategy<Vapor.Response, ApodiniError> {
        .abort(error)
    }
}

public struct VaporBlobResponseTransformer: ResultTransformer {
    public init() { }
    
    public func transform(input: Apodini.Response<Blob>) -> Vapor.Response {
        var body: Vapor.Response.Body
        
        if let content = input.content {
            body = Vapor.Response.Body(buffer: content.byteBuffer)
        } else {
            body = Vapor.Response.Body()
        }
        
        return Vapor.Response(status: input.responseStatus,
                              headers: HTTPHeaders(input.information),
                              body: body)
    }
    
    public func handle(error: ApodiniError) -> ErrorHandlingStrategy<Vapor.Response, ApodiniError> {
            .abort(error)
    }
}

private extension Apodini.Response {
    var responseStatus: HTTPResponseStatus {
        switch self.status {
        case let .some(status):
            return HTTPStatus(status)
        case .none:
            if self.content == nil {
                return .noContent
            } else {
                return .ok
            }
        }
    }
}
