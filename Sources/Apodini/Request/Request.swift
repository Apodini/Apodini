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
    func parameter<T: Decodable>(for id: String) throws -> T
    /// body
    func bodyParameter<T: Decodable>() throws -> T?
    /// body string
    func bodyParameter() throws -> String?
    /// The EventLoop associated with this request
    var eventLoop: EventLoop { get }
    /// endpoint
    var endpoint: String? { get }
    /// database
    var database: Any? { get }
}

typealias TotallyNotVaporRequest = Vapor.Request

extension TotallyNotVaporRequest: Request {
    public func parameter<T: Decodable>(for id: String) throws -> T {
        try self.query.get(at: id)
    }

    public func bodyParameter<T: Decodable>() throws -> T? {
        let length = self.body.data?.readableBytes ?? 0
        return try self.body.data?.getJSONDecodable(T.self, at: 0, length: length)
    }

    public func bodyParameter() throws -> String? {
        return self.body.string
    }

    public var endpoint: String? {
        self.route?.path.string
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
    
    
    mutating func inject(using request: Request, with decoder: RequestInjectableDecoder? = nil) throws {
        self.request = request
    }
}
