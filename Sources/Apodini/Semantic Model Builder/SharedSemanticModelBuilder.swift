//
// Created by Andi on 22.11.20.
//

import NIO
@_implementationOnly import Vapor
@_implementationOnly import AssociatedTypeRequirementsVisitor

/// This struct is used to model the RootPath for the root of the endpoints tree
struct RootPath: _PathComponent {
    var description: String {
        ""
    }

    func append<P>(to pathBuilder: inout P) where P: PathBuilder {
        fatalError("RootPath instances should not be appended to anything")
    }
}

class WebServiceModel {
    fileprivate let root = EndpointsTreeNode(path: RootPath())
    fileprivate var finishedParsing = false
    
    lazy var rootEndpoints: [AnyEndpoint] = {
        if !finishedParsing {
            fatalError("rootEndpoints of the WebServiceModel was accessed before parsing was finished!")
        }
        return root.endpoints.map { _, endpoint -> AnyEndpoint in endpoint }
    }()
    var relationships: [EndpointRelationship] {
        root.relationships
    }
    
    fileprivate func addEndpoint<H: Handler>(_ endpoint: Endpoint<H>, at paths: [PathComponent]) {
        var endpoint = endpoint
        root.addEndpoint(&endpoint, at: paths)
    }
}

class SharedSemanticModelBuilder: SemanticModelBuilder, InterfaceExporterVisitor {
    private var interfaceExporters: [AnyInterfaceExporter] = []

    let webService: WebServiceModel
    let rootNode: EndpointsTreeNode

    override init(_ app: Application) {
        webService = WebServiceModel()
        rootNode = webService.root // used to provide the unit test a reference to the root of the tree
        super.init(app)
    }

    func with<T: InterfaceExporter>(exporter exporterType: T.Type) -> Self {
        let exporter = exporterType.init(app)
        interfaceExporters.append(AnyInterfaceExporter(exporter))
        return self
    }

    func with<T: StaticInterfaceExporter>(exporter exporterType: T.Type) -> Self {
        let exporter = exporterType.init(app)
        interfaceExporters.append(AnyInterfaceExporter(exporter))
        return self
    }


    override func register<H: Handler>(handler: H, withContext context: Context) {
        super.register(handler: handler, withContext: context)
        
        let operation = context.get(valueFor: OperationContextKey.self)
        var paths = context.get(valueFor: PathComponentContextKey.self)
        let guards = context.get(valueFor: GuardContextKey.self).allActiveGuards
        let responseTransformers = context.get(valueFor: ResponseContextKey.self)
        
        let parameterBuilder = ParameterBuilder(from: handler)
        parameterBuilder.build()
        
        for parameter in parameterBuilder.parameters {
            if parameter.kind == .path && !paths.contains(where: { ($0 as? _PathComponent)?.description == ":\(parameter.id)" }) {
                if let pathComponent = parameterBuilder.requestInjectables[parameter.label] as? _PathComponent {
                    paths.append(pathComponent)
                }
            }
        }
        
        let endpoint = Endpoint(
            identifier: {
                if let identifier = handler.getExplicitlySpecifiedIdentifier() {
                    return identifier
                } else {
                    let handlerIndexPath = context.get(valueFor: HandlerIndexPath.ContextKey.self)
                    return AnyHandlerIdentifier(handlerIndexPath.rawValue)
                }
            }(),
            handler: handler,
            context: context,
            operation: operation,
            guards: guards,
            responseTransformers: responseTransformers,
            parameters: parameterBuilder.parameters
        )
        
        webService.addEndpoint(endpoint, at: paths)
    }
    
    override func finishedRegistration() {
        super.finishedRegistration()
        
        webService.finishedParsing = true
        
        // currently only for debugging purposes
        print(webService.root.debugDescription)

        if interfaceExporters.isEmpty {
            print("[WARN] There aren't any Interface Exporters registered!")
        }

        interfaceExporters.acceptAll(self)
    }

    func visit<I>(exporter: I) where I: InterfaceExporter {
        call(exporter: exporter, for: webService.root)
        exporter.finishedExporting(webService)
    }

    func visit<I>(staticExporter: I) where I: StaticInterfaceExporter {
        call(exporter: staticExporter, for: webService.root)
        staticExporter.finishedExporting(webService)
    }

    private func call<I: BaseInterfaceExporter>(exporter: I, for node: EndpointsTreeNode) {
        for (_, endpoint) in node.endpoints {
            #warning("The result of export is currently unused. Could that be useful in the future?")
            _ = endpoint.exportEndpoint(on: exporter)
        }
        
        for child in node.children {
            call(exporter: exporter, for: child)
        }
    }
}


private protocol IdentifiableHandlerATRVisitorHelper: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = IdentifiableHandlerATRVisitorHelper
    associatedtype Input = IdentifiableHandler
    associatedtype Output
    func callAsFunction<T: IdentifiableHandler>(_ value: T) -> Output
}


private struct IdentifiableHandlerATRVisitor: IdentifiableHandlerATRVisitorHelper {
    func callAsFunction<T: IdentifiableHandler>(_ value: T) -> AnyHandlerIdentifier {
        value.handlerId
    }
}


extension Handler {
    /// If `self` is an `IdentifiableHandler`, returns the handler's `handlerId`. Otherwise nil
    internal func getExplicitlySpecifiedIdentifier() -> AnyHandlerIdentifier? {
        // Intentionally using the if-let here to make sure we get an error
        // if for some reason the ATRVisitor's return type isn't an optional anymore,
        // since that (a guaranteed non-nil return value) would defeat the whole point of this function
        if let identifier = IdentifiableHandlerATRVisitor()(self) {
            return identifier
        } else {
            return nil
        }
    }
}
