#if DEBUG
@testable import Apodini
import XCTest


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
        
        XCTAssertApodiniApplicationNotRunning()
    }
    
    @discardableResult
    public func XCTCheckHandler<H: Handler>(
        _ handler: H,
        @MockBuilder<H.Response.Content> _ mocks: () -> ([Mock<H.Response.Content>]) = { [MockRequest()] },
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> H.Response.Content? where H.Response.Content: Equatable {
        try XCTCheckHandler(
            handler,
            mocks: mocks(),
            exporter: MockExporter(app),
            { message() },
            file: file,
            line: line
        )
    }
    
    @discardableResult
    public func XCTCheckHandler<H: Handler>(
        _ handler: H,
        mocks: [Mock<H.Response.Content>],
        exporter mockExporter: MockExporter,
        interfaceExporterVisitors: [InterfaceExporterVisitor] = [],
        _ message: () -> String = { "" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> H.Response.Content? where H.Response.Content: Equatable {
        let endpoint = try handler.mockEndpoint(
            application: app,
            interfaceExporter: mockExporter,
            interfaceExporterVisitors: interfaceExporterVisitors
        )
        
        let eventLoop = app.eventLoopGroup.next()
        var context: ConnectionContext<MockExporter>?
        
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
    
    public func XCTCheckComponent<C: Component>(
        _ component: C,
        @CheckHandlerBuilder _ checks: () -> ([AnyCheckHandler]) = { [] },
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try XCTCheckComponent(
            component,
            exporter: MockExporter(app),
            checks: checks(),
            message
        )
    }
    
    public func XCTCheckComponent<C: Component>(
        _ component: C,
        exporter mockExporter: MockExporter,
        interfaceExporterVisitors: [InterfaceExporterVisitor] = [],
        checks: [AnyCheckHandler] = [],
        _ message: () -> String = { "" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let endpoints = try component.mockEndpoints(
            application: app,
            interfaceExporter: mockExporter,
            interfaceExporterVisitors: interfaceExporterVisitors
        )
        
        for check in checks {
            try check.check(endpoints: endpoints, app: app, exporter: mockExporter)
        }
    }
}
#endif
