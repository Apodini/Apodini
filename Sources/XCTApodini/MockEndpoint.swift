//
// Created by Andreas Bauer on 25.12.20.
//

#if DEBUG
@testable import Apodini
import struct Foundation.UUID

//public protocol ContextNodeAddable {
//    func add(to contextNode: ContextNode)
//}
//
//public struct ContextValue<C: OptionalContextKey>: ContextNodeAddable {
//    let contextKey: C.Type
//    let value: C.Value
//
//
//    public init(_ contextKey: C.Type, value: C.Value) {
//        self.contextKey = contextKey
//        self.value = value
//    }
//
//
//    public func add(to contextNode: ContextNode) {
//        contextNode.addContext(contextKey.self, value: value, scope: .current)
//    }
//}
//
//@_functionBuilder
//public struct ContextBuilder {
//    public static func buildBlock(_ paths: ContextNodeAddable...) -> [ContextNodeAddable] {
//        paths
//    }
//}
//
//extension Context {
//    public static var empty: Context {
//        Context(contextNode: ContextNode())
//    }
//
//    static func containing(@ContextBuilder _ contextValues: () -> ([ContextNodeAddable])) -> Context {
//        let contextNode = ContextNode()
//        for contextValue in contextValues() {
//            contextValue.add(to: contextNode)
//        }
//        return Context(contextNode: contextNode)
//    }
//}

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



// MARK: Mock Endpoint
extension Handler {
    public func mockEndpoint(
        app: Application? = nil
    ) -> Endpoint<Self> {
        mockEndpoint(app: app, wrappedHandlerOfType: Self.self)
    }
    
    /// Creates a basic Endpoint Model from the `Handler`.
    /// If `Application` is defined, it will be injected into all `ApplicationInjectables`.
    /// - Note: This endpoint's identifier is not guaranteed to be stable
    public func mockEndpoint<H: Handler>(
        app: Application? = nil,
        wrappedHandlerOfType: H.Type = H.self
    ) -> Endpoint<H> {
        let mockSyntaxTreeVisitor = MockSyntaxTreeVisitor()
        self.accept(mockSyntaxTreeVisitor)
        let context = Context(contextNode: mockSyntaxTreeVisitor.currentNode)
        
        guard let anyHandler = mockSyntaxTreeVisitor.handler, var handler = anyHandler as? H else {
            fatalError("Could not cast the handler \(String(describing: mockSyntaxTreeVisitor.handler)) to the type \(H.self)")
        }
        var guards = context.get(valueFor: GuardContextKey.self)
        var responseTransformers = context.get(valueFor: ResponseTransformerContextKey.self)
        
        if let application = app {
            handler = handler.inject(app: application)
            guards = guards.inject(app: application)
            responseTransformers = responseTransformers.inject(app: application)
        }

        return Endpoint(
            identifier: self.getExplicitlySpecifiedIdentifier() ?? AnyHandlerIdentifier(UUID().uuidString),
            handler: handler,
            context: context,
            operation: nil,
            guards: guards,
            responseTransformers: responseTransformers
        )
    }
    
    public func newMockEndpoint<H: Handler>(
        application: Application,
        wrappedHandlerOfType: H.Type = H.self
    ) throws -> Endpoint<H> {
        try XCTUnwrap(newMockEndpoint(application: application) as? Endpoint<H>)
    }
    
    public func newMockEndpoint(
        application: Application
    ) throws -> AnyEndpoint {
        let semanticModelBuilder = SemanticModelBuilder(application)
        let syntaxTreeVisitor = SyntaxTreeVisitor(modelBuilder: semanticModelBuilder)
        
        self.accept(syntaxTreeVisitor)
        syntaxTreeVisitor.finishParsing()
        
        return try XCTUnwrap(semanticModelBuilder.webService.root.collectEndpoints().first, "Could not find Handler in the MockExporter")
    }
}

@discardableResult
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
func _XCTCheckHandler<H: Handler, T: Encodable & Equatable>(
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
    let endpoint = try handler().mockEndpoint(app: application())
    let exporter = _MockExporter(application())
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
//
//@discardableResult
//public func XCTCheckHandler<H: Handler, T: Encodable & Equatable>(
//    _ handler: @autoclosure () throws -> H,
//    application: @escaping @autoclosure () -> Application,
//    @ContextBuilder contextValues: () -> ([ContextNodeAddable]) = { [] },
//    connectionState: ConnectionState = .end,
//    parameters: Any??...,
//    status: @escaping @autoclosure () -> Status? = nil,
//    responseType: T.Type = T.self,
//    connectionEffect: @autoclosure () -> ConnectionEffect = .close,
//    _ message: @autoclosure () -> String = "",
//    file: StaticString = #filePath,
//    line: UInt = #line
//) throws -> T? {
//    try _XCTCheckHandler(
//        handler,
//        application: application,
//        contextValues: contextValues,
//        connectionState: connectionState,
//        parameters: parameters,
//        status: status,
//        responseType: responseType,
//        connectionEffect: connectionEffect,
//        message,
//        file: file,
//        line: line
//    )
//}
//
//@discardableResult
//func _XCTCheckHandler<H: Handler, T: Encodable & Equatable>(
//    _ handler: () throws -> H,
//    application: () -> Application,
//    @ContextBuilder contextValues: () -> ([ContextNodeAddable]) = { [] },
//    connectionState: ConnectionState = .end,
//    parameters: [Any??],
//    status: () -> Status?,
//    responseType: T.Type = T.self,
//    connectionEffect: () -> ConnectionEffect,
//    _ message: () -> String,
//    file: StaticString = #filePath,
//    line: UInt = #line
//) throws -> T? {
//    let contextNode = ContextNode()
//    for contextValue in contextValues() {
//        contextValue.add(to: contextNode)
//    }
//    let context = Context(contextNode: contextNode)
//
//    let response = try XCTUnwrap(
//        try handler()
//            ._mockRequest(
//                app: application(),
//                context: context,
//                connectionState: connectionState,
//                parameters: parameters,
//                guards: [],
//                responseTransformers: [],
//                responseContent: T.self
//            )
//            .typed(T.self),
//        "Expected a `Response` with a content of type `\(T.self)`. \(message())"
//    )
//
//    XCTAssertEqual(response.connectionEffect, connectionEffect(), message())
//    XCTAssertEqual(response.status, status(), message())
//
//    return response.content
//}
//
//@discardableResult
//public func XCTCheckHandler<H: Handler, T: Encodable & Equatable>(
//    _ handler: @autoclosure () throws -> H,
//    application: @escaping @autoclosure () -> Application,
//    @ContextBuilder contextValues: () -> ([ContextNodeAddable]) = { [] },
//    connectionState: ConnectionState = .end,
//    parameters: Any...,
//    status: @escaping @autoclosure () -> Status? = nil,
//    responseType: T.Type = T.self,
//    content expectedContent: @autoclosure () -> T?,
//    connectionEffect: @autoclosure () -> ConnectionEffect = .close,
//    _ message: @autoclosure () -> String = "",
//    file: StaticString = #filePath,
//    line: UInt = #line
//) throws -> T? {
//    let content = try _XCTCheckHandler(
//        handler,
//        application: application,
//        contextValues: contextValues,
//        connectionState: connectionState,
//        parameters: parameters,
//        status: status,
//        responseType: responseType,
//        connectionEffect: connectionEffect,
//        message,
//        file: file,
//        line: line
//    )
//    XCTAssertEqual(content, expectedContent(), message())
//    return content
//}

//@discardableResult
//public func XCTCheckHandler<H: Handler, T: Encodable & Equatable>(
//    _ handler: @autoclosure () throws -> H,
//    using: @escaping @autoclosure () -> Application,
//    context: @escaping @autoclosure () -> Context = .empty,
//    parameters parameterValues: Any??...,
//    status: @escaping @autoclosure () -> Status? = nil,
//    content:  @autoclosure () -> T?,
//    connectionEffect: @autoclosure () -> ConnectionEffect? = nil,
//    _ message: @autoclosure () -> String = "",
//    file: StaticString = #filePath,
//    line: UInt = #line
//) throws -> T? where H.Response == Response<T> {
//    fatalError()
//}
//
//@discardableResult
//public func XCTCheckHandler<H: Handler, T: Encodable & Equatable>(
//    _ handler: @autoclosure () throws -> H,
//    using: @escaping @autoclosure () -> Application,
//    context: @escaping @autoclosure () -> Context = .empty,
//    parameters parameterValues: Any??...,
//    status: @escaping @autoclosure () -> Status? = nil,
//    content:  @autoclosure () -> T?,
//    connectionEffect: @autoclosure () -> ConnectionEffect? = nil,
//    _ message: @autoclosure () -> String = "",
//    file: StaticString = #filePath,
//    line: UInt = #line
//) throws -> T? where H.Response == EventLoopFuture<T> {
//    fatalError()
//}
#endif
