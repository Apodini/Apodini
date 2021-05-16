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
    #warning("TODO: Make internal")
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
#endif
