//
//  Request.swift
//  
//
//  Created by Paul Schmiedmayer on 7/12/20.
//

import Foundation
import NIO
@_implementationOnly import Vapor

/// A type representing a server response.
public protocol Request {
    /// parameters
    func parameter<T: Codable>(for parameter: Parameter<T>) throws -> T
    /// The EventLoop associated with this request
    var eventLoop: EventLoop { get }
    /// database
    var database: Any? { get }
}

typealias VaporRequest = Vapor.Request

extension VaporRequest: Request {
    public func parameter<T: Codable>(for parameter: Parameter<T>) throws -> T {
        #warning("Implement propper encoding / decoding")
        switch parameter.option(for: PropertyOptionKey.http) {
        case .path where T.self is LosslessStringConvertible:
            guard let parameter = parameters.get(parameter.id.uuidString) as? T else {
                #warning("Implement propper errors")
                throw Vapor.Abort(.badRequest)
            }
            return parameter
        case .query:
            guard let name = parameter.name else {
                #warning("Implement propper errors")
                throw Vapor.Abort(.badRequest)
            }
            return try query.get(T.self, at: name)
        case .body:
            let length = self.body.data?.readableBytes ?? 0
            let body = try? self.body.data?.getJSONDecodable(T.self, at: 0, length: length)
            let string = self.body.string as? T
            guard let result = body ?? string else {
                #warning("Implement propper errors")
                throw Vapor.Abort(.badRequest)
            }
            return result
        default:
            #warning("Implement propper errors")
            throw Vapor.Abort(.badRequest)
        }
    }

    public var database: Any? {
        self.db
    }
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
    
    
    mutating func inject(using request: Request) throws {
        self.request = request
    }
}
