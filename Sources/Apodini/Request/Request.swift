//
//  Request.swift
//  
//
//  Created by Paul Schmiedmayer on 7/12/20.
//
import Foundation
import NIO
import protocol Fluent.Database

/// A type representing a server response.
public protocol Request {
    /// parameters
    func parameter<T: Codable>(for parameter: UUID) throws -> T?
    /// The EventLoop associated with this request
    var eventLoop: EventLoop { get }
    /// database
    var database: Fluent.Database? { get }
}

enum RequestDecodingError: Error {
    case couldNotDecodeParameter(for: UUID)
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


struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        try self.value.encode(to: encoder)
    }
}
