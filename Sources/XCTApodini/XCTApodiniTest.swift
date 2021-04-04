#if DEBUG
@testable import Apodini
import ApodiniUtils
import ApodiniDatabase
import FluentSQLiteDriver
import XCTest


extension XCTestExpectation {
    public convenience init(expectedFulfillmentCount: Int) {
        self.init()
        
        self.expectedFulfillmentCount = expectedFulfillmentCount
        self.assertForOverFulfill = true
    }
}

public protocol MockableParameter {
    var id: String { get }
    
    func getValue<Type: Decodable>(for parameter: EndpointParameter<Type>) -> Type??
}

public struct UnnamedParameter<Value: Decodable>: MockableParameter {
    let value: Value?
    
    
    public var id: String {
        "\(ObjectIdentifier(Value.self)):\(Int.random())"
    }
    
    
    public init(_ value: Value?) {
        self.value = value
    }
    
    
    public func getValue<Type: Decodable>(for parameter: EndpointParameter<Type>) -> Type?? {
        guard Type.self == Value.self else {
            return nil
        }
        
        guard let unwrappedValue = value else {
            return .some(.none) // Explict null value that as passed in from the consumer (developer writing the test case)
        }
        
        guard let casted = unwrappedValue as? Type else {
            fatalError("MockExporter: Could not cast value \(String(describing: unwrappedValue)) to type \(Type.self) for '\(parameter.description)'")
        }
        
        return casted
    }
}

public struct NamedParameter<Value: Decodable>: MockableParameter {
    let name: String
    let unnamedParameter: UnnamedParameter<Value>
    
    
    public var id: String {
        "\(ObjectIdentifier(Value.self)):\(name)"
    }
    
    
    public init(_ name: String, value: Value?) {
        self.name = name
        self.unnamedParameter = UnnamedParameter(value)
    }
    
    
    public func getValue<Type: Decodable>(for parameter: EndpointParameter<Type>) -> Type?? {
        guard parameter.name == self.name else {
            return nil
        }
        
        return unnamedParameter.getValue(for: parameter)
    }
}

@_functionBuilder
public struct MockableParameterBuilder {
    public static func buildBlock(_ parameters: MockableParameter...) -> [MockableParameter] {
        parameters
    }
}


public enum Expectation<R: Encodable & Equatable> {
    public static var empty: Expectation<Empty> {
        Expectation<Empty>.response(nil)
    }
    
    public static var throwError: Expectation<Empty> {
        Expectation<Empty>.error
    }
    
    
    public static func status(_ status: Status) -> Expectation<Empty> {
        Expectation<Empty>.response(status: status, nil)
    }
    
    public static func connectionEffect(_ connectionEffect: ConnectionEffect) -> Expectation<Empty> {
        Expectation<Empty>.response(connectionEffect: connectionEffect, nil)
    }
    
    case response(status: Status? = nil, connectionEffect: ConnectionEffect = .close, R?)
    case error
    
    
    func check(_ responseFuture: EventLoopFuture<Response<EnrichedContent>>) throws -> R? {
        switch self {
        case let .response(status, connectionEffect, expectedResponse):
            let untypedResponse = try responseFuture.wait()
            let response = try XCTUnwrap(untypedResponse.typed(R.self))
            
            XCTAssertEqual(response.content, expectedResponse)
            XCTAssertEqual(response.connectionEffect, connectionEffect)
            XCTAssertEqual(response.status, status)
            
            return response.content
        case .error:
            do {
                let response = try responseFuture.wait()
                XCTFail("Expected an error that was not encountered. Got: \(response)")
            } catch {
                return nil
            }
            return nil
        }
    }
}


public struct MockExporterRequest: ExporterRequest, WithEventLoop {
    public let eventLoop: EventLoop
    let doNotReduceRequest: Bool
    let mockableParameters: [String: MockableParameter]
    
    
    private init(on eventLoop: EventLoop, doNotReduceRequest: Bool = false, mockableParameters: [String: MockableParameter]) {
        self.eventLoop = eventLoop
        self.mockableParameters = mockableParameters
        self.doNotReduceRequest = doNotReduceRequest
    }
    
    public init(on eventLoop: EventLoop, doNotReduceRequest: Bool = false, mockableParameters: [MockableParameter] = []) {
        self.init(on: eventLoop, doNotReduceRequest: doNotReduceRequest, mockableParameters: Dictionary(uniqueKeysWithValues: mockableParameters.map { ($0.id, $0) }))
    }
    
    public init<Value: Decodable>(on eventLoop: EventLoop, doNotReduceRequest: Bool = false, _ values: Value...) {
        self.init(on: eventLoop, doNotReduceRequest: doNotReduceRequest, mockableParameters: values.map { UnnamedParameter($0) })
    }
    
    public init(on eventLoop: EventLoop, doNotReduceRequest: Bool = false, @MockableParameterBuilder mockableParameters: () -> ([MockableParameter])) {
        self.init(on: eventLoop, doNotReduceRequest: doNotReduceRequest, mockableParameters: mockableParameters())
    }
    
    
    public func reduce(to new: MockExporterRequest) -> MockExporterRequest {
        if new.doNotReduceRequest {
            return new
        } else {
            return MockExporterRequest(on: new.eventLoop, mockableParameters: self.mockableParameters.merging(new.mockableParameters) { $1 })
        }
    }
}


public struct MockOptions: OptionSet {
    public static let doNotReduceRequest = MockOptions(rawValue: 0b001)
    public static let doNotReuseConnection = MockOptions(rawValue: 0b011)
    public static let subsequentRequest: MockOptions = []
    
    
    public let rawValue: UInt8
    
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}


public class Mock<R: Encodable & Equatable> {
    let options: MockOptions
    
    
    public init(options: MockOptions = .subsequentRequest) {
        self.options = options
    }
    
    
    @discardableResult
    func mock(
        usingConnectionContext context: inout ConnectionContext<_MockExporter>?,
        requestNewConnectionContext: () -> (ConnectionContext<_MockExporter>),
        eventLoop: EventLoop,
        lastResponse: R?
    ) throws -> R? {
        if context == nil || options.contains(.doNotReuseConnection) {
            context = requestNewConnectionContext()
        }
        
        return lastResponse
    }
}

public class ExecuteClosure<R: Encodable & Equatable>: Mock<R> {
    let closure: () -> ()
    
    public init(options: MockOptions = .subsequentRequest, closure: @escaping () -> ()) {
        self.closure = closure
        super.init(options: options)
    }
    
    
    override func mock(
        usingConnectionContext context: inout ConnectionContext<_MockExporter>?,
        requestNewConnectionContext: () -> (ConnectionContext<_MockExporter>),
        eventLoop: EventLoop,
        lastResponse: R?
    ) throws -> R? {
        let response = try super.mock(
            usingConnectionContext: &context,
            requestNewConnectionContext: requestNewConnectionContext,
            eventLoop: eventLoop,
            lastResponse: lastResponse
        )
        
        closure()
        
        return response
    }
}

public class MockObservedListener<R: Encodable & Equatable>: Mock<R> {
    struct Listener: ObservedListener {
        let eventLoop: EventLoop
        let handler: (EventLoopFuture<Response<EnrichedContent>>) -> ()
        
        func onObservedDidChange(_ observedObject: AnyObservedObject, in context: ConnectionContext<_MockExporter>) {
            handler(context.handle(eventLoop: eventLoop, observedObject: observedObject))
        }
    }
    
    let expectation: Expectation<R>
    let timeoutExpectation: XCTestExpectation
    
    
    public init(_ expectation: Expectation<R>, timeoutExpectation: XCTestExpectation, options: MockOptions = .subsequentRequest) {
        self.expectation = expectation
        self.timeoutExpectation = timeoutExpectation
        
        super.init(options: options)
    }
    
    
    override func mock(
        usingConnectionContext context: inout ConnectionContext<_MockExporter>?,
        requestNewConnectionContext: () -> (ConnectionContext<_MockExporter>),
        eventLoop: EventLoop,
        lastResponse: R?
    ) throws -> R? {
        let response = try super.mock(
            usingConnectionContext: &context,
            requestNewConnectionContext: requestNewConnectionContext,
            eventLoop: eventLoop,
            lastResponse: lastResponse
        )
        
        context?.register(listener: Listener(eventLoop: eventLoop) { responseFuture in
            do {
                let _ = try self.expectation.check(responseFuture)
                self.timeoutExpectation.fulfill()
            } catch {
                XCTFail("Encountered an unexpected error when using an MockObservedListener")
            }
        })
        
        return response
    }
}


public class MockRequest<R: Encodable & Equatable>: Mock<R> {
    let connectionState: ConnectionState
    let expectation: Expectation<R>?
    let mockableParameters: [MockableParameter]
    
    
    private init(
        connectionState: ConnectionState = .end,
        expectation: Expectation<R>?,
        options: MockOptions = .subsequentRequest,
        parameters: [MockableParameter]
    ) {
        self.connectionState = connectionState
        self.expectation = expectation
        self.mockableParameters = parameters
        
        super.init(options: options)
    }
    
    public convenience init(
        connectionState: ConnectionState = .end,
        expectation: Expectation<R>,
        options: MockOptions = .subsequentRequest,
        @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }
    ) {
        self.init(connectionState: connectionState, expectation: expectation, options: options, parameters: parameters())
    }
    
    public convenience init(
        connectionState: ConnectionState = .end,
        expectation response: R,
        options: MockOptions = .subsequentRequest,
        @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }
    ) {
        self.init(connectionState: connectionState, expectation: .response(response), options: options, parameters: parameters())
    }
    
    public convenience init(
        connectionState: ConnectionState = .end,
        options: MockOptions = .subsequentRequest,
        @MockableParameterBuilder parameters: () -> ([MockableParameter]) = { [] }
    ) {
        self.init(connectionState: connectionState, expectation: nil, options: options, parameters: parameters())
    }
    
    
    override func mock(
        usingConnectionContext context: inout ConnectionContext<_MockExporter>?,
        requestNewConnectionContext: () -> (ConnectionContext<_MockExporter>),
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
        
        return try expectation?.check(responseFuture)
    }
}

@_functionBuilder
public struct MockBuilder<Response: Encodable & Equatable> {
    public static func buildBlock<Response>(_ mocks: Mock<Response>...) -> [Mock<Response>] {
        mocks
    }
}

open class XCTApodiniTest: XCTestCase {
    // Vapor Application
    // swiftlint:disable implicitly_unwrapped_optional
    open var app: Application!
    
    override open func setUpWithError() throws {
        try super.setUpWithError()
        app = Application()
    }
    
    override open func tearDownWithError() throws {
        try super.tearDownWithError()
        app.shutdown()
    }
    
    open func database() throws -> Database {
        try XCTUnwrap(self.app.database)
    }
    
    open func addMigrations(_ migrations: Migration...) throws {
        app.databases.use(
            .sqlite(.memory),
            as: .init(string: "ApodiniTest"),
            isDefault: true
        )
        
        app.migrations.add(migrations)
        
        try app.autoMigrate().wait()
    }
    
    @discardableResult
    public func newerXCTCheckHandler<H: Handler>(
        _ handler: H,
        @MockBuilder<H.Response.Content> _ mocks: () -> ([Mock<H.Response.Content>]) = { [MockRequest()] },
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> H.Response.Content? where H.Response.Content: Equatable {
        try _newerXCTCheckHandler(handler, mocks(), { message() }, file: file, line: line)
    }
    
    @discardableResult
    public func _newerXCTCheckHandler<H: Handler>(
        _ handler: H,
        _ mocks: [Mock<H.Response.Content>],
        _ message: () -> String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> H.Response.Content? where H.Response.Content: Equatable {
        let endpoint = try handler.newMockEndpoint(application: app)
        
        let mockExporter = _MockExporter(app)
        let eventLoop = app.eventLoopGroup.next()
        var context: ConnectionContext<_MockExporter>?
        
        let response = try mocks
            .reduce(Optional<H.Response.Content>.none) { lastResponse, mock in
                return try mock.mock(
                    usingConnectionContext: &context,
                    requestNewConnectionContext: { endpoint.createConnectionContext(for: mockExporter) },
                    eventLoop: eventLoop,
                    lastResponse: lastResponse
                )
            }
        
        return response
    }
}
#endif
