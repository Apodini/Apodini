//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

#if DEBUG
@testable import Apodini

public class MockRequest<R: Encodable>: Mock<R> {
    fileprivate struct Assertion {
        fileprivate static var none: Assertion {
            Assertion { responseFuture in
                try responseFuture.wait().typed(R.self)?.content
            }
        }
        
        fileprivate static func expectation(_ expectation: Expectation<R>) -> Assertion where R: Equatable {
            Assertion { responseFuture in
                try expectation.check(responseFuture)
            }
        }
        
        fileprivate static func closure(_ closure: @escaping (R) throws -> ()) -> Assertion {
            Assertion { responseFuture in
                let content = try XCTUnwrap(responseFuture.wait().typed(R.self)?.content)
                try closure(content)
                return content
            }
        }
        
        
        private var _assertAndTransform: (EventLoopFuture<Response<EnrichedContent>>) throws -> R?
        
        
        private init(_ assertAndTransform: @escaping (EventLoopFuture<Response<EnrichedContent>>) throws -> R?) {
            self._assertAndTransform = assertAndTransform
        }
        
        
        fileprivate func assertAndTransform(_ future: EventLoopFuture<Response<EnrichedContent>>) throws -> R? {
            try _assertAndTransform(future)
        }
    }
    
    private let connectionState: ConnectionState
    private let assertion: Assertion
    private let mockableParameters: [MockableParameter]
    
    
    private init(
        connectionState: ConnectionState = .end,
        assertion: Assertion,
        options: MockOptions = .subsequentRequest,
        parameters: [MockableParameter]
    ) {
        self.connectionState = connectionState
        self.assertion = assertion
        self.mockableParameters = parameters
        
        super.init(options: options)
    }
    
    public convenience init(
        connectionState: ConnectionState = .end,
        expectation: Expectation<R>,
        options: MockOptions = .subsequentRequest,
        @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }
    ) where R: Equatable {
        self.init(connectionState: connectionState, assertion: .expectation(expectation), options: options, parameters: parameters())
    }
    
    public convenience init(
        connectionState: ConnectionState = .end,
        expectation response: R,
        options: MockOptions = .subsequentRequest,
        @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }
    ) where R: Equatable {
        self.init(connectionState: connectionState, assertion: .expectation(.response(response)), options: options, parameters: parameters())
    }
    
    public convenience init(
        connectionState: ConnectionState = .end,
        assertion: @escaping (R) throws -> (),
        options: MockOptions = .subsequentRequest,
        @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }
    ) {
        self.init(connectionState: connectionState, assertion: .closure(assertion), options: options, parameters: parameters())
    }
    
    public convenience init(
        connectionState: ConnectionState = .end,
        options: MockOptions = .subsequentRequest,
        @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }
    ) {
        self.init(connectionState: connectionState, assertion: .none, options: options, parameters: parameters())
    }
    
    
    override func mock(
        usingConnectionContext context: inout ConnectionContext<MockExporter>?,
        requestNewConnectionContext: () -> (ConnectionContext<MockExporter>),
        eventLoop: EventLoop,
        lastResponse: R?
    ) throws -> R? {
        try super.mock(
            usingConnectionContext: &context,
            requestNewConnectionContext: requestNewConnectionContext,
            eventLoop: eventLoop,
            lastResponse: lastResponse
        )
    
        let responseFuture = try XCTUnwrap(context)
            .handle(
                request: MockExporterRequest(
                    on: eventLoop,
                    doNotReduceRequest: self.options.contains(.doNotReduceRequest),
                    mockableParameters: self.mockableParameters
                ),
                final: self.connectionState
            )
        
        return try assertion.assertAndTransform(responseFuture)
    }
}
#endif
