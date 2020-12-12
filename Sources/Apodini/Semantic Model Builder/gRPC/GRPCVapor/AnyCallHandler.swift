//
//  AnyCallHandler.swift
//
//
//  Created by Michael Schlicker on 15.01.20.
//

import Vapor

public protocol AnyCallHandler {
    var vaporRequest: Vapor.Request { get set }
    var errorResponse: Vapor.Response { get }
    var response: EventLoopFuture<Vapor.Response> { get set }
}


extension AnyCallHandler {
    public var errorResponse: Response {
        Response.init(status: .badRequest,
                      version: .init(major: 2, minor: 0),
                      headers: vaporRequest.headers,
                      body: Response.Body.init())
    }
}
