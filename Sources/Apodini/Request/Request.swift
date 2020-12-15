//
//  Request.swift
//  
//
//  Created by Paul Schmiedmayer on 7/12/20.
//

import Vapor

/// A type representing a server response.
public protocol Request {
    /// parameters
    func parameter<T: Codable>(for parameter: UUID) throws -> T
    func bodyData() throws -> Data
    func getQuery(at: String) throws -> String
    /// The EventLoop associated with this request
    var eventLoop: EventLoop { get }
    /// database
    var database: Any? { get }
}

enum RequestDecodingError: Error {
    case couldNotDecodeParameter(for: UUID)
}

typealias VaporRequest = Vapor.Request

extension VaporRequest: Request {
    public func parameter<T: Codable>(for parameter: UUID) throws -> T {
        return "" as! T
    }

    public func bodyData() throws -> Data {
        guard let byteBuffer = body.data,
              let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
            throw Vapor.Abort(.internalServerError, reason: "Could not read the HTTP request's body")
        }
        return data
    }

    public func getQuery(at query: String) throws -> String {
        try self.query.get(at: query)
    }

    public var database: Any? {
        self.db
    }
}

struct AnyRequest {

}


@propertyWrapper
// swiftlint:disable:next type_name
struct _Request: RequestInjectable {
    private var request: Request?
    
    
    var wrappedValue: Request {
        guard let request = request else {
            fatalError("You can only access the request while you handle a request")
        }
        
        return request
    }
    
    
    init() { }
    
    
    mutating func inject(using request: Request, with decoder: RequestInjectableDecoder? = nil) throws {
        self.request = request
    }
}


struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        try self.value.encode(to: encoder)
    }
}
