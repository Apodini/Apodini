#if DEBUG || RELEASE_TESTING
@testable import Apodini
import XCTest


open class XCTApodiniTest: XCTestCase {
    private struct EmptyConfiguration: Configuration {
        func configure(_ app: Application) {}
    }
    
    private struct TestWebService<C: Component>: WebService {
        let content: C
        let configuration: Configuration
        
        
        init(_ content: C, configuration: Configuration = EmptyConfiguration()) {
            self.content = content
            self.configuration = configuration
        }
        
        @available(*, deprecated, message: "A TestWebService must be initialized with a component")
        init() {
            fatalError("A TestWebService must be initialized with a component")
        }
        
        @available(*, deprecated, message: "A TestWebService must be initialized with a component")
        init(from decoder: Decoder) throws {
            fatalError("A TestWebService must be initialized with a component")
        }
    }
    
    
    // Vapor Application
    // swiftlint:disable implicitly_unwrapped_optional
    open var app: Application!
    
    
    public var mockExporter: MockInterfaceExporter {
        try! app.getInterfaceExporter(MockInterfaceExporter.self)
    }
    
    
    override open func setUpWithError() throws {
        try super.setUpWithError()
        app = Application()
    }
    
    override open func tearDownWithError() throws {
        try super.tearDownWithError()
        app.shutdown()
        
        XCTAssertApodiniApplicationNotRunning()
    }
    
    @discardableResult
    public func XCTCheckHandler<H: Handler>(
        _ handler: H,
        configuration: Configuration = MockExporter(),
        @MockBuilder<H.Response.Content> _ mocks: () -> ([Mock<H.Response.Content>]) = { [MockRequest()] },
        _ message: @escaping @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> H.Response.Content? where H.Response.Content: Equatable {
        try XCTCheckHandler(
            handler,
            configuration: configuration,
            mocks: mocks(),
            message,
            file: file,
            line: line
        )
    }
    
    @discardableResult
    public func XCTCheckHandler<H: Handler>(
        _ handler: H,
        configuration: Configuration = MockExporter(),
        mocks: [Mock<H.Response.Content>],
        _ message: @escaping () -> String = { "" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> H.Response.Content? where H.Response.Content: Equatable {
        try XCTCheckComponent(
            handler,
            configuration: configuration,
            checks: [
                CheckHandler<H>(mockIdentifier: .first, mocks, message())
            ],
            message
        ) as? H.Response.Content
    }
    
    @discardableResult
    public func XCTCheckComponent<C: Component>(
        _ component: C,
        configuration: Configuration = MockExporter(),
        @CheckHandlerBuilder _ checks: () -> ([AnyCheckHandler]) = { [] },
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Any? {
        try XCTCheckComponent(
            component,
            configuration: configuration,
            checks: checks(),
            { message() },
            file: file,
            line: line
        )
    }
    
    @discardableResult
    public func XCTCheckComponent<C: Component>(
        _ component: C,
        configuration: Configuration = MockExporter(),
        checks: [AnyCheckHandler] = [],
        _ message: () -> String = { "" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Any? {
        let webService = TestWebService(component, configuration: configuration)
        try TestWebService.start(waitForCompletion: false, webService: webService)
        let mockExporter = try app.getInterfaceExporter(MockInterfaceExporter.self)
        
        var lastResponse: Any?
        for check in checks {
            lastResponse = try check.anyMock(usingExporter: mockExporter)
        }
        return lastResponse
    }
    
    @discardableResult
    public func XCTCreateMockEndpoint<H: Handler>(
        _ handler: H,
        configuration: Configuration = MockExporter(),
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Endpoint<H> {
        try XCTCreateMockEndpoint(handlerType: H.self, identifier: .first, configuration: configuration, { handler }, message(), file: file, line: line)
    }
    
    @discardableResult
    public func XCTCreateMockEndpoint<C: Component, H: Handler>(
        handlerType: H.Type = H.self,
        identifier: MockIdentifier = .first,
        configuration: Configuration = MockExporter(),
        @ComponentBuilder _ component: () -> C,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Endpoint<H> {
        let webService = TestWebService(component(), configuration: configuration)
        return try XCTCreateMockEndpoint(handlerType: H.self, identifier: identifier, webService: webService, message(), file: file, line: line)
    }
    
    @discardableResult
    func XCTCreateMockEndpoint<W: WebService, H: Handler>(
        handlerType: H.Type = H.self,
        identifier: MockIdentifier = .first,
        webService: W,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Endpoint<H> {
        W.start(app: app, webService: webService)
        try app.boot()
        
        let mockExporter = try app.getInterfaceExporter(MockInterfaceExporter.self)
        let mockRequestHandler = try XCTUnwrap(try mockExporter.handler(identifiedBy: identifier) as? MockRequestHandler<H>)
        return mockRequestHandler.endpoint
    }
}
#endif
