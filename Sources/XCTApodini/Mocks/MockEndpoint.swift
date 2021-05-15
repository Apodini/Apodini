//
// Created by Andreas Bauer on 25.12.20.
//

#if DEBUG
@testable import Apodini
import struct Foundation.UUID

private class MockSyntaxTreeVisitor: SyntaxTreeVisitor {
    var handler: Any?
    
    override func enterContent(_ block: () throws -> Void) rethrows {
        try block()
    }
    
    override func enterComponentContext(_ block: () throws -> Void) rethrows {
        try block()
    }
    
    override func addContext<C: OptionalContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        currentNode.addContext(contextKey, value: value, scope: scope)
    }
    
    override func visit<H: Handler>(handler: H) {
        addContext(HandlerIndexPath.ContextKey.self, value: HandlerIndexPath(rawValue: "0"), scope: .current)
        self.handler = handler
    }
    
    override func finishParsing() {}
}

extension Component {
    func mockEndpoints(
        application: Application,
        interfaceExporter: MockExporter? = nil,
        interfaceExporterVisitors: [InterfaceExporterVisitor] = []
    ) throws -> [AnyEndpoint] {
        let semanticModelBuilder: SemanticModelBuilder
        if let interfaceExporter = interfaceExporter {
            semanticModelBuilder = SemanticModelBuilder(application).with(exporter: interfaceExporter)
        } else {
            semanticModelBuilder = SemanticModelBuilder(application)
        }
        let syntaxTreeVisitor = SyntaxTreeVisitor(modelBuilder: semanticModelBuilder)
        
        self.accept(syntaxTreeVisitor)
        syntaxTreeVisitor.finishParsing()
        
        for interfaceExporter in semanticModelBuilder.interfaceExporters {
            for interfaceExporterVisitor in interfaceExporterVisitors {
                interfaceExporter.accept(interfaceExporterVisitor)
            }
        }
        
        return semanticModelBuilder.webService.root.collectEndpoints()
    }
}

// MARK: Mock Endpoint
extension Handler {
    @available(*, deprecated, message: "Please use mockEndpoint instead.", renamed: "mockEndpoint")
    public func oldMockEndpoint(
        app: Application? = nil
    ) -> Endpoint<Self> {
        oldMockEndpoint(app: app, wrappedHandlerOfType: Self.self)
    }
    
    /// Creates a basic Endpoint Model from the `Handler`.
    /// If `Application` is defined, it will be injected into all `ApplicationInjectables`.
    /// - Note: This endpoint's identifier is not guaranteed to be stable
    @available(*, deprecated, message: "Please use mockEndpoint instead.", renamed: "mockEndpoint")
    public func oldMockEndpoint<H: Handler>(
        app: Application? = nil,
        wrappedHandlerOfType: H.Type = H.self
    ) -> Endpoint<H> {
        let mockSyntaxTreeVisitor = MockSyntaxTreeVisitor()
        self.accept(mockSyntaxTreeVisitor)
        let context = Context(contextNode: mockSyntaxTreeVisitor.currentNode)
        
        guard let anyHandler = mockSyntaxTreeVisitor.handler, let handler = anyHandler as? H else {
            fatalError("Could not cast the handler \(String(describing: mockSyntaxTreeVisitor.handler)) to the type \(H.self)")
        }
        let guards = context.get(valueFor: GuardContextKey.self)
        let responseTransformers = context.get(valueFor: ResponseTransformerContextKey.self)
        
        var blackboard: Blackboard
        if let application = app {
            blackboard = LocalBlackboard<LazyHashmapBlackboard, GlobalBlackboard<LazyHashmapBlackboard>>(
                GlobalBlackboard<LazyHashmapBlackboard>(application),
                using: handler,
                context)
        } else {
            blackboard = LocalBlackboard<LazyHashmapBlackboard, LazyHashmapBlackboard>(LazyHashmapBlackboard(), using: handler, context)
        }

        return Endpoint(
            handler: handler,
            blackboard: blackboard,
            guards: guards,
            responseTransformers: responseTransformers
        )
    }
    
    #warning("TODO: Make internal")
    public func mockEndpoint<H: Handler>(
        application: Application,
        wrappedHandlerOfType: H.Type = H.self
    ) throws -> Endpoint<H> {
        try XCTUnwrap(mockEndpoint(application: application) as? Endpoint<H>)
    }
    
    #warning("TODO: Make internal")
    public func mockEndpoint(
        application: Application,
        interfaceExporter: MockExporter? = nil,
        interfaceExporterVisitors: [InterfaceExporterVisitor] = []
    ) throws -> AnyEndpoint {
        return try XCTUnwrap(
            self.mockEndpoints(
                application: application,
                interfaceExporter: interfaceExporter,
                interfaceExporterVisitors: interfaceExporterVisitors
            ).first,
            "Could not export the Handler using the MockExporter"
        )
    }
}

@discardableResult
@available(*, deprecated, message: "Please subclass XCTApodiniTest and use XCTCheckHandler provided by XCTApodiniTest instead.")
public func XCTCheckHandler<H: Handler, T: Encodable & Equatable>(
    _ handler: @autoclosure () throws -> H,
    application: @escaping @autoclosure () -> Application,
    connectionState: ConnectionState = .end,
    request: @escaping @autoclosure () -> MockExporterRequest? = nil,
    status: @escaping @autoclosure () -> Status? = nil,
    responseType: T.Type = T.self,
    connectionEffect: @autoclosure () -> ConnectionEffect = .close,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> T? {
    try _XCTCheckHandler(
        handler,
        application: application,
        connectionState: connectionState,
        request: request,
        status: status,
        responseType: responseType,
        connectionEffect: connectionEffect,
        message,
        file: file,
        line: line
    )
}

@discardableResult
@available(*, deprecated, message: "Please subclass XCTApodiniTest and use XCTCheckHandler provided by XCTApodiniTest instead.")
public func XCTCheckHandler<H: Handler, T: Encodable & Equatable>(
    _ handler: @autoclosure () throws -> H,
    application: @escaping @autoclosure () -> Application,
    connectionState: ConnectionState = .end,
    request: @escaping @autoclosure () -> MockExporterRequest? = nil,
    status: @escaping @autoclosure () -> Status? = nil,
    responseType: T.Type = T.self,
    content expectedContent: @autoclosure () -> T?,
    connectionEffect: @autoclosure () -> ConnectionEffect = .close,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> T? {
    let content = try _XCTCheckHandler(
        handler,
        application: application,
        connectionState: connectionState,
        request: request,
        status: status,
        responseType: responseType,
        connectionEffect: connectionEffect,
        message,
        file: file,
        line: line
    )
    XCTAssertEqual(content, expectedContent(), message())
    return content
}

@discardableResult
private func _XCTCheckHandler<H: Handler, T: Encodable & Equatable>(
    _ handler: () throws -> H,
    application: () -> Application,
    connectionState: ConnectionState = .end,
    request: () -> MockExporterRequest?,
    status: () -> Status?,
    responseType: T.Type = T.self,
    connectionEffect: () -> ConnectionEffect,
    _ message: () -> String,
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> T? {
    let eventLoop = application().eventLoopGroup.next()
    let endpoint = try handler().oldMockEndpoint(app: application())
    let exporter = MockExporter(application())
    let connectionContext = endpoint.createConnectionContext(for: exporter)
    
    let request = request() ?? MockExporterRequest(on: eventLoop, mockableParameters: [])
    
    let response = try XCTUnwrap(
        try connectionContext.handle(
                request: request,
                eventLoop: application().eventLoopGroup.next(),
                connectionState: connectionState
            )
            .wait()
            .typed(responseType)
    )
    
    XCTAssertEqual(response.connectionEffect, connectionEffect(), message())
    XCTAssertEqual(response.status, status(), message())
    
    return response.content
}
#endif
