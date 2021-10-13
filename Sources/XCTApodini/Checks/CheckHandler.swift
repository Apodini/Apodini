//
//  CheckHandler.swift
//
//
//  Created by Paul Schmiedmayer on 5/15/21.
//

import Apodini


public class AnyCheckHandler {
    fileprivate let mockIdentifier: MockIdentifier
    fileprivate let anyMocks: [AnyMock]
    fileprivate let message: () -> String
    fileprivate let file: StaticString
    fileprivate let line: UInt
    
    init(
        mockIdentifier: MockIdentifier,
        anyMocks: [AnyMock],
        message: @escaping () -> String,
        file: StaticString,
        line: UInt
    ) {
        self.mockIdentifier = mockIdentifier
        self.anyMocks = anyMocks
        self.message = message
        self.file = file
        self.line = line
    }
    
    
    func anyMock(usingExporter exporter: MockInterfaceExporter) throws -> Any? {
        var lastResponse: Any?
        for mock in anyMocks {
            lastResponse = try mock.anyMock(usingExporter: exporter, mockIdentifier: mockIdentifier, lastResponse: lastResponse)
        }
        return lastResponse
    }
}


public final class CheckHandler<H: Handler>: AnyCheckHandler {
    private let mocks: [Mock<H.Response.Content>]
    
    
    public init(
        mockIdentifier: MockIdentifier,
        _ mocks: [Mock<H.Response.Content>] = [MockRequest()],
        _ message: @autoclosure @escaping () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        self.mocks = mocks
        super.init(mockIdentifier: mockIdentifier, anyMocks: mocks, message: message, file: file, line: line)
    }
    
    public convenience init(
        @MockBuilder<H.Response.Content> _ mocks: @escaping () -> ([Mock<H.Response.Content>]) = { [MockRequest()] },
        _ message: @autoclosure @escaping () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        self.init(mockIdentifier: .first, mocks(), message(), file: file, line: line)
    }

    public convenience init(
        identifier: AnyHandlerIdentifier,
        @MockBuilder<H.Response.Content> _ mocks: @escaping () -> ([Mock<H.Response.Content>]) = { [MockRequest()] },
        _ message: @autoclosure @escaping () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        self.init(
            mockIdentifier: .identifier(identifier),
            mocks(),
            message(),
            file: file,
            line: line
        )
    }

    public convenience init(
        path: String,
        @MockBuilder<H.Response.Content> _ mocks: @escaping () -> ([Mock<H.Response.Content>]) = { [MockRequest()] },
        _ message: @autoclosure @escaping () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        self.init(
            mockIdentifier: .path(path),
            mocks(),
            message(),
            file: file,
            line: line
        )
    }
    
    
    func mock(usingExporter exporter: MockInterfaceExporter) throws -> H.Response.Content? {
        var lastResponse: H.Response.Content?
        for mock in mocks {
            lastResponse = try mock.mock(usingExporter: exporter, mockIdentifier: .first, lastResponse: lastResponse)
        }
        return lastResponse
    }
}
