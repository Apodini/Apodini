//
//  MockExporter.swift
//  
//
//  Created by Paul Schmiedmayer on 3/8/21.
//

#if DEBUG || RELEASE_TESTING
@testable import Apodini
import ApodiniExtension


public enum MockExporterError: Error {
    case noMatchingEndpoint(description: String)
    case noMatchingContentType(description: String)
}


public enum MockIdentifier {
    case first
    case path(String)
    case identifier(AnyHandlerIdentifier)
}


/// Public Apodini Interface Exporter for basic HTTP
public final class MockExporter: Configuration {
    public var mockInterfaceExporter: MockInterfaceExporter?
    
    
    public init() {}
    
    
    public func configure(_ app: Apodini.Application) {
        // We explicitly explicittylt reuse the same MockInterfaceExporter across instances of MockExporter
        let mockInterfaceExporter = mockInterfaceExporter ?? MockInterfaceExporter(app)
        
        app.registerExporter(exporter: mockInterfaceExporter)
        self.mockInterfaceExporter = mockInterfaceExporter
    }
}


open class MockInterfaceExporter: InterfaceExporter {
    public let app: Application
    private var _model: WebServiceModel?
    private var mockRequestHandlers: [AnyMockRequestHandler] = []
    
    
    public var model: WebServiceModel {
        try! XCTUnwrap(_model, "Accessed the WebServiceModel before the MockInterfaceExporter finished parsing")
    }
    
    
    public static func decodingStrategy(for endpoint: AnyEndpoint) -> AnyDecodingStrategy<AnyMockRequest> {
        MockRequestEndpointDecodingStrategyStrategy().applied(to: endpoint)
    }
    
    
    required public init(_ app: Apodini.Application) {
        self.app = app
    }

    
    open func export<H: Handler>(_ endpoint: Endpoint<H>) {
        mockRequestHandlers.append(MockRequestHandler(endpoint, eventLoop: app.eventLoopGroup.next()))
    }
    
    open func export<H: Handler>(blob endpoint: Endpoint<H>) -> () where H.Response.Content == Blob {
        mockRequestHandlers.append(MockRequestHandler(endpoint, eventLoop: app.eventLoopGroup.next()))
    }
    
    
    open func finishedExporting(_ webService: WebServiceModel) {
        _model = webService
    }
    
    func execute<R>(handlerIdentifiedBy identifier: MockIdentifier, request: MockRequest<R>) throws -> Response<R> {
        try handler(identifiedBy: identifier).handle(request)
    }
    
    func register(_ listener: ObservedListener, toHandlerIdentifiedBy identifier: MockIdentifier) throws {
        try handler(identifiedBy: identifier).register(listener)
    }
    
    func handler(identifiedBy identifier: MockIdentifier) throws -> AnyMockRequestHandler {
        let requestHandler: AnyMockRequestHandler
        switch identifier {
        case .first:
            requestHandler = try firstHandler()
        case let .path(path):
            requestHandler = try handlerWith(path: path)
        case let .identifier(identifier):
            requestHandler = try handlerWith(id: identifier)
        }
        return requestHandler
    }
    
    private func firstHandler() throws -> AnyMockRequestHandler {
        guard let mockRequestHandler = mockRequestHandlers.first else {
            throw MockExporterError.noMatchingEndpoint(description: "No Handler found in the MockExporter")
        }
        return mockRequestHandler
    }
    
    private func handlerWith(id handlerId: AnyHandlerIdentifier) throws -> AnyMockRequestHandler {
        guard let mockRequestHandler = mockRequestHandlers.first(where: { mockRequestHandler in
            guard let identifier = mockRequestHandler.anyEndpoint[DSLSpecifiedIdentifier.self].value else {
                return false
            }
            return identifier == handlerId
        }) else {
            throw MockExporterError.noMatchingEndpoint(description: "No Handler with the id \(handlerId) found in the MockExporter")
        }
        
        return mockRequestHandler
    }
    
    private func handlerWith(path: String) throws -> AnyMockRequestHandler {
        guard let mockRequestHandler = mockRequestHandlers.first(where: { mockRequestHandler in
            let endpointPath = mockRequestHandler.anyEndpoint[EndpointPathComponentsHTTP.self].value
            let stringPath = path.split(separator: "/")
            
            if endpointPath.count != stringPath.count {
                return false
            }
            
            let comparison = zip(stringPath, endpointPath)
            for pair in comparison {
                switch (pair.0, pair.1) {
                case ("", .root), ("*", .root):
                    continue
                case let (stringElement, .string(element)):
                    if stringElement != element && stringElement != "*" {
                        return false
                    }
                case ("*", .parameter(_)):
                    continue
                default:
                    return false
                }
            }
            
            return true
        }) else {
            throw MockExporterError.noMatchingEndpoint(description: "No Handler for the path \(path) found in the MockExporter")
        }
        
        return mockRequestHandler
    }
}
#endif
