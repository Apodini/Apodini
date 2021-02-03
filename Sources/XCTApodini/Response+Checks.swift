//
//  Response+Checks.swift
//  
//
//  Created by Paul Schmiedmayer on 2/3/21.
//

@testable import Apodini
import NIO
import XCTest


public func XCTCheckResponse<C, T: Encodable & Equatable>(
    _ response: @autoclosure () throws -> EventLoopFuture<Response<C>>,
    expectedContent: @autoclosure () -> T,
    connectionEffect: @autoclosure () -> ConnectionEffect? = nil,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    try check(
        response: { try response().wait() },
        status: nil,
        expectedContent: expectedContent,
        connectionEffect: connectionEffect,
        message: message,
        file: file,
        line: line
    )
}


public func XCTCheckResponse<C, T: Encodable & Equatable>(
    _ response: @autoclosure () throws -> EventLoopFuture<Response<C>>,
    status: @escaping @autoclosure () -> Status?,
    expectedContent: @autoclosure () -> T,
    connectionEffect: @autoclosure () -> ConnectionEffect? = nil,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    try check(
        response: { try response().wait() },
        status: status,
        expectedContent: expectedContent,
        connectionEffect: connectionEffect,
        message: message,
        file: file,
        line: line
    )
}

public func XCTCheckResponse<C, T: Encodable & Equatable>(
    _ response: @autoclosure () throws -> Response<C>,
    expectedContent: @autoclosure () -> T,
    connectionEffect: @autoclosure () -> ConnectionEffect? = nil,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    try check(
        response: response,
        status: nil,
        expectedContent: expectedContent,
        connectionEffect: connectionEffect,
        message: message,
        file: file,
        line: line
    )
}


public func XCTCheckResponse<C, T: Encodable & Equatable>(
    _ response: @autoclosure () throws -> Response<C>,
    status: @escaping @autoclosure () -> Status?,
    expectedContent:  @autoclosure () -> T,
    connectionEffect: @autoclosure () -> ConnectionEffect? = nil,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    try check(
        response: response,
        status: status,
        expectedContent: expectedContent,
        connectionEffect: connectionEffect,
        message: message,
        file: file,
        line: line
    )
}

private func check<C, T: Encodable & Equatable>(
    response: () throws -> Response<C>,
    status: (() -> Status?)?,
    expectedContent: () -> T,
    connectionEffect: () -> ConnectionEffect?,
    message: () -> String,
    file: StaticString,
    line: UInt
) throws {
    guard let response = try response().typed(T.self) else {
        XCTFail("Expected a `Response` with a content of type `\(T.self)`")
        throw ApodiniError.init(type: .other)
    }
    
    if let connectionEffect = connectionEffect() {
        XCTAssertEqual(response.connectionEffect, connectionEffect)
    }
    if let status = status {
        XCTAssertEqual(response.status, status())
    }
    
    let content = try XCTUnwrap(response.content, message(), file: file, line: line)
    XCTAssertEqual(content, expectedContent())
}
