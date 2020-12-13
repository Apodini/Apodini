//
//  Response.swift
//  
//
//  Created by Tim Gymnich on 13.12.20.
//

import Vapor

protocol ResponseEncoder {
    func encode<T: Encodable>(_ value: T, request: Vapor.Request) throws -> EventLoopFuture<Vapor.Response>
}

struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        try self.value.encode(to: encoder)
    }
}
