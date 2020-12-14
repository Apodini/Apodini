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
    func parameter<T: Codable>(for parameter: Parameter<T>) throws -> T
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
    public func parameter<T: Codable>(for parameter: Parameter<T>) throws -> T {
        switch parameter.option(for: PropertyOptionKey.http) {
        case .path where T.self is LosslessStringConvertible:
            guard let result = parameters.get(parameter.id.uuidString) as? T else {
                throw RequestDecodingError.couldNotDecodeParameter(for: parameter.id)
            }
            return result
        case .query:
            guard let name = parameter.name else {
                throw RequestDecodingError.couldNotDecodeParameter(for: parameter.id)
            }
            return try query.get(T.self, at: name)
        case .body:
            let length = self.body.data?.readableBytes ?? 0
            let body = try? self.body.data?.getJSONDecodable(T.self, at: 0, length: length)
            let string = self.body.string as? T
            guard let result = body ?? string else {
                throw RequestDecodingError.couldNotDecodeParameter(for: parameter.id)
            }
            return result
        default:
            throw RequestDecodingError.couldNotDecodeParameter(for: parameter.id)
        }
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
