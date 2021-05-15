//
//  CheckHandler.swift
//  
//
//  Created by Paul Schmiedmayer on 5/15/21.
//

#if DEBUG
import Apodini


public struct CheckHandler<H: Handler>: AnyCheckHandler {
    private let _check: ([AnyEndpoint], Application, MockExporter) throws -> ()
    
    public init(
        identifyingEndpoint: @escaping ([AnyEndpoint]) throws -> AnyEndpoint,
        @MockBuilder<EnrichedContent> _ mocks: @escaping () -> ([Mock<EnrichedContent>]) = { [MockRequest()] },
        _ message: @autoclosure @escaping () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        _check = { endpoints, app, mockExporter in
            let endpoint = try identifyingEndpoint(endpoints)
            let eventLoop = app.eventLoopGroup.next()
            var context: ConnectionContext<MockExporter>?
            
            _ = try mocks()
                .reduce(Optional<EnrichedContent>.none) { lastResponse, mock in
                    return try mock.mock(
                        usingConnectionContext: &context,
                        requestNewConnectionContext: { endpoint.createConnectionContext(for: mockExporter) },
                        eventLoop: eventLoop,
                        lastResponse: lastResponse
                    )
                }
        }
    }
    
    public init(
        index: Int,
        @MockBuilder<EnrichedContent> _ mocks: @escaping () -> ([Mock<EnrichedContent>]) = { [MockRequest()] },
        _ message: @autoclosure @escaping () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        self.init(
            identifyingEndpoint: {
                $0[index]
            },
            mocks,
            message(),
            file: file,
            line: line
        )
    }
    
    public init(
        path: String,
        @MockBuilder<EnrichedContent> _ mocks: @escaping () -> ([Mock<EnrichedContent>]) = { [MockRequest()] },
        _ message: @autoclosure @escaping () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        self.init(
            identifyingEndpoint: { endpoints in
                try XCTUnwrap(
                    endpoints.first(where: { endpoint in
                        let endpointPath = endpoint
                            .absolutePath
                            .map({ $0.description })
                            .joined(separator: "/")
                        return endpointPath == path
                    })
                )
            },
            mocks,
            message(),
            file: file,
            line: line
        )
    }
    
    public init(
        identifyingEndpoint: @escaping ([AnyEndpoint]) throws -> AnyEndpoint,
        @MockBuilder<H.Response.Content> _ mocks: @escaping () -> ([Mock<H.Response.Content>]) = { [MockRequest()] },
        _ message: @autoclosure @escaping () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        _check = { endpoints, app, mockExporter in
            let endpoint = try identifyingEndpoint(endpoints)
            let eventLoop = app.eventLoopGroup.next()
            var context: ConnectionContext<MockExporter>?
            
            _ = try mocks()
                .reduce(Optional<H.Response.Content>.none) { lastResponse, mock in
                    return try mock.mock(
                        usingConnectionContext: &context,
                        requestNewConnectionContext: { endpoint.createConnectionContext(for: mockExporter) },
                        eventLoop: eventLoop,
                        lastResponse: lastResponse
                    )
                }
        }
    }
    
    public init(
        index: Int,
        @MockBuilder<H.Response.Content> _ mocks: @escaping () -> ([Mock<H.Response.Content>]) = { [MockRequest()] },
        _ message: @autoclosure @escaping () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        self.init(
            identifyingEndpoint: {
                $0[index]
            },
            mocks,
            message(),
            file: file,
            line: line
        )
    }
    
    public init(
        path: String,
        @MockBuilder<H.Response.Content> _ mocks: @escaping () -> ([Mock<H.Response.Content>]) = { [MockRequest()] },
        _ message: @autoclosure @escaping () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        self.init(
            identifyingEndpoint: { endpoints in
                try XCTUnwrap(
                    endpoints.first(where: { endpoint in
                        let endpointPath = endpoint
                            .absolutePath
                            .map({ $0.description })
                            .joined(separator: "/")
                        return endpointPath == path
                    })
                )
            },
            mocks,
            message(),
            file: file,
            line: line
        )
    }
    
    
    public func check(endpoints: [AnyEndpoint], app: Application, exporter mockExporter: MockExporter) throws {
        try _check(endpoints, app, mockExporter)
    }
}
#endif
