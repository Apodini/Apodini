//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

#if DEBUG || RELEASE_TESTING
@testable import Apodini
import XCTest
import ApodiniNetworking


public struct WrappedRESTResponse<T: Decodable>: Decodable {
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case links = "_links"
    }
    public let data: T
    public let links: [String: String]?
    
    public init(data: T, links: [String: String]? = nil) {
        self.data = data
        self.links = links
    }
}

extension WrappedRESTResponse: Hashable where T: Hashable {}
extension WrappedRESTResponse: Equatable where T: Equatable {}


/// Returns the decoded contents of a REST response
public func XCTUnwrapRESTResponse<T: Decodable>(_: T.Type, from response: LKHTTPResponse) throws -> WrappedRESTResponse<T> {
    try response.bodyStorage.getFullBodyData(decodedAs: WrappedRESTResponse<T>.self)
}


/// Returns the decoded contents of a REST response's `data` field
public func XCTUnwrapRESTResponseData<T: Decodable>(_: T.Type, from response: LKHTTPResponse) throws -> T {
    try XCTUnwrapRESTResponse(T.self, from: response).data
}


extension LKRequestResponseBodyStorage {
    @available(*, deprecated)
    public func getDecodedRESTResponseData<T: Codable>(_ type: T.Type) throws -> T {
        try self.getFullBodyData(decodedAs: WrappedRESTResponse<T>.self).data
    }
}


extension Empty: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }
}

/// Adds the possibility to easily check the `Response<T>` of a `Handler` by investigating the `Response`
/// - Parameters:
///   - response: The `Response` that should be investigated
///   - content: The expected content
///   - connectionEffect: The expected `ConnectionEffect`
///   - message: The message that should be posted in case of a failure
///   - file: The origin of the `XCTCheckResponse` call
///   - line: The origin of the `XCTCheckResponse` call
/// - Throws: Thows an error in case of failure
@discardableResult
public func XCTCheckResponse<C, T: Encodable & Equatable>(
    _ response: @autoclosure () throws -> EventLoopFuture<Response<C>>,
    _ type: T.Type = T.self,
    content: @autoclosure () -> T?,
    connectionEffect: @autoclosure () -> ConnectionEffect? = nil,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> T? {
    try _XCTCheckResponse(
        response: { try response().wait() },
        type: T.self,
        status: nil,
        content: content,
        connectionEffect: connectionEffect,
        message: message,
        file: file,
        line: line
    )
}


/// Adds the possibility to easily check the `Response<T>` of a `Handler` by investigating the `Response`
/// - Parameters:
///   - response: The `Response` that should be investigated
///   - status: The expected `Status`
///   - content: The expected content
///   - connectionEffect: The expected `ConnectionEffect`
///   - message: The message that should be posted in case of a failure
///   - file: The origin of the `XCTCheckResponse` call
///   - line: The origin of the `XCTCheckResponse` call
/// - Throws: Thows an error in case of failure
@discardableResult
public func XCTCheckResponse<C, T: Encodable & Equatable>(
    _ response: @autoclosure () throws -> EventLoopFuture<Response<C>>,
    _ type: T.Type = T.self,
    status: @escaping @autoclosure () -> Status?,
    content: @autoclosure () -> T?,
    connectionEffect: @autoclosure () -> ConnectionEffect? = nil,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> T? {
    try _XCTCheckResponse(
        response: { try response().wait() },
        type: T.self,
        status: status,
        content: content,
        connectionEffect: connectionEffect,
        message: message,
        file: file,
        line: line
    )
}

/// Adds the possibility to easily check the `Response<T>` of a `Handler` by investigating the `Response`
/// - Parameters:
///   - response: The `Response` that should be investigated
///   - content: The expected content
///   - connectionEffect: The expected `ConnectionEffect`
///   - message: The message that should be posted in case of a failure
///   - file: The origin of the `XCTCheckResponse` call
///   - line: The origin of the `XCTCheckResponse` call
/// - Throws: Throws an error in case of failure
@discardableResult
public func XCTCheckResponse<C, T: Encodable & Equatable>(
    _ response: @autoclosure () throws -> Response<C>,
    _ type: T.Type = T.self,
    content: @autoclosure () -> T?,
    connectionEffect: @autoclosure () -> ConnectionEffect? = nil,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> T? {
    try _XCTCheckResponse(
        response: response,
        type: T.self,
        status: nil,
        content: content,
        connectionEffect: connectionEffect,
        message: message,
        file: file,
        line: line
    )
}


/// Adds the possibility to easily check the `Response<T>` of a `Handler` by investigating the `Response`
/// - Parameters:
///   - response: The `Response` that should be investigated
///   - content: The expected content
///   - connectionEffect: The expected `ConnectionEffect`
///   - message: The message that should be posted in case of a failure
///   - file: The origin of the `XCTCheckResponse` call
///   - line: The origin of the `XCTCheckResponse` call
/// - Throws: Thows an error in case of failure
@discardableResult
public func XCTCheckResponse<C, T: Encodable & Equatable>(
    _ response: @autoclosure () throws -> Response<C>,
    _ type: T.Type = T.self,
    status: @escaping @autoclosure () -> Status?,
    content:  @autoclosure () -> T?,
    connectionEffect: @autoclosure () -> ConnectionEffect? = nil,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> T? {
    try _XCTCheckResponse(
        response: response,
        type: T.self,
        status: status,
        content: content,
        connectionEffect: connectionEffect,
        message: message,
        file: file,
        line: line
    )
}

// swiftlint:disable:next function_parameter_count
private func _XCTCheckResponse<C, T: Encodable & Equatable>(
    response: () throws -> Response<C>,
    type: T.Type = T.self,
    status: (() -> Status?)?,
    content expectedContent: () -> T?,
    connectionEffect: () -> ConnectionEffect?,
    message: () -> String,
    file: StaticString,
    line: UInt
) throws -> T? {
    let response = try XCTUnwrap(try response().typed(T.self), "Expected a `Response` with a content of type `\(T.self)`. \(message())")
    
    if let connectionEffect = connectionEffect() {
        XCTAssertEqual(response.connectionEffect, connectionEffect, message())
    }
    if let status = status {
        XCTAssertEqual(response.status, status(), message())
    }
    
    let content = response.content
    
    XCTAssertEqual(content, expectedContent(), message())
    
    return content
}
#endif
