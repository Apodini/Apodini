//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

#if DEBUG || RELEASE_TESTING
@testable import Apodini
import ApodiniExtension
import XCTest


public class AnyMockRequest: RequestBasis {
    private let mockableParameters: [MockableParameter]
    public let information: Set<AnyInformation>
    
    
    public var description: String {
        return """
        Parameters: \(mockableParameters.map(\.description).joined(separator: "/n"))
        Information: \(information.map(\.description).joined(separator: "/n"))
        """
    }
    
    public var debugDescription: String {
        "MockRequest: \(self.description)"
    }
    
    public var remoteAddress: SocketAddress? {
        try? SocketAddress(ipAddress: "0.0.0.0", port: 80)
    }
    
    
    public init<R: Encodable>(_ mockRequest: MockRequest<R>) {
        self.mockableParameters = mockRequest.mockableParameters
        self.information = mockRequest.information
    }
    
    
    func getValue<E: Decodable>(for parameter: EndpointParameter<E>) throws -> E {
        guard let value: E = mockableParameters.compactMap({ $0.getValue(for: parameter) }).first else {
            throw DecodingError.keyNotFound(
                parameter.name,
                DecodingError.Context(
                    codingPath: [parameter.name],
                    debugDescription: "No \(parameter.parameterType) parameter with name \(parameter.name) and type \(E.self) present in request \(description)",
                    underlyingError: nil
                )
            )
        }
        
        return value
    }
}


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
        
        
        private var _assertAndTransform: (EventLoopFuture<Response<R>>) throws -> R?
        
        
        private init(_ assertAndTransform: @escaping (EventLoopFuture<Response<R>>) throws -> R?) {
            self._assertAndTransform = assertAndTransform
        }
        
        
        fileprivate func assertAndTransform(_ future: EventLoopFuture<Response<R>>) throws -> R? {
            try _assertAndTransform(future)
        }
    }
    
    private let connectionState: ConnectionState
    private let assertion: Assertion
    fileprivate let information: Set<AnyInformation>
    fileprivate let mockableParameters: [MockableParameter]
    
    
    private init(
        connectionState: ConnectionState = .end,
        assertion: Assertion,
        options: MockOptions = .subsequentRequest,
        information: Set<AnyInformation>,
        parameters: [MockableParameter]
    ) {
        self.connectionState = connectionState
        self.assertion = assertion
        self.information = information
        self.mockableParameters = parameters
        
        super.init(options: options)
    }
    
    public convenience init(
        connectionState: ConnectionState = .end,
        expectation: Expectation<R>,
        options: MockOptions = .subsequentRequest,
        information: Set<AnyInformation> = [],
        @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }
    ) where R: Equatable {
        self.init(connectionState: connectionState, assertion: .expectation(expectation), options: options, information: information, parameters: parameters())
    }
    
    public convenience init(
        connectionState: ConnectionState = .end,
        expectation response: R,
        options: MockOptions = .subsequentRequest,
        information: Set<AnyInformation> = [],
        @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }
    ) where R: Equatable {
        self.init(connectionState: connectionState, assertion: .expectation(.response(response)), options: options, information: information, parameters: parameters())
    }
    
    public convenience init(
        connectionState: ConnectionState = .end,
        assertion: @escaping (R) throws -> (),
        options: MockOptions = .subsequentRequest,
        information: Set<AnyInformation> = [],
        @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }
    ) {
        self.init(connectionState: connectionState, assertion: .closure(assertion), options: options, information: information, parameters: parameters())
    }
    
    public convenience init(
        connectionState: ConnectionState = .end,
        options: MockOptions = .subsequentRequest,
        information: Set<AnyInformation> = [],
        @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }
    ) {
        self.init(connectionState: connectionState, assertion: .none, options: options, information: information, parameters: parameters())
    }
    
    
    public override func mock(usingExporter exporter: MockInterfaceExporter, mockIdentifier: MockIdentifier, lastResponse: R?) throws -> R? {
        try exporter.execute(handlerIdentifiedBy: mockIdentifier, request: self).content
    }
}
#endif
