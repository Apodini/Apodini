//
// Created by Andi on 22.11.20.
//

import NIO
@_implementationOnly import AssociatedTypeRequirementsVisitor

class WebServiceModel {
    fileprivate let root = EndpointsTreeNode(path: .root)
    private var finishedParsing = false
    
    lazy var rootEndpoints: [AnyEndpoint] = {
        if !finishedParsing {
            fatalError("rootEndpoints of the WebServiceModel was accessed before parsing was finished!")
        }
        return root.endpoints.map { _, endpoint -> AnyEndpoint in endpoint }
    }()
    var relationships: [EndpointRelationship] {
        root.relationships
    }

    func finish() {
        finishedParsing = true
        root.finish()
    }
    
    func addEndpoint<H: Handler>(_ endpoint: inout Endpoint<H>, at paths: [PathComponent]) {
        var context = EndpointInsertionContext(pathComponents: paths)
        context.assertRootPath()

        root.addEndpoint(&endpoint, context: &context)
    }
}

class SharedSemanticModelBuilder: SemanticModelBuilder, InterfaceExporterVisitor {
    private var interfaceExporters: [AnyInterfaceExporter] = []
    /// This property (which is to be made configurable) toggles if the default `ParameterNamespace`
    /// (which is the strictest option possible) can be overridden by Exporters, which may allow more lenient
    /// restrictions. In the end the Exporter with the strictest `ParameterNamespace` will dictate the requirements
    /// towards parameter naming.
    private let allowLenientParameterNamespaces = true

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
        let serviceType = context.get(valueFor: ServiceTypeContextKey.self)
        let paths = context.get(valueFor: PathComponentContextKey.self)
        var guards = context.get(valueFor: GuardContextKey.self).allActiveGuards
        var responseTransformers = context.get(valueFor: ResponseTransformerContextKey.self)
        
        guards = applicationInjectables(to: guards)
        responseTransformers = applicationInjectables(to: responseTransformers)
        
        var endpoint = Endpoint(
            identifier: {
                if let identifier = handler.getExplicitlySpecifiedIdentifier() {
                    return identifier
                } else {
                    let handlerIndexPath = context.get(valueFor: HandlerIndexPath.ContextKey.self)
                    return AnyHandlerIdentifier(handlerIndexPath.rawValue)
                }
            }(),
            handler: handler.inject(app: app),
            context: context,
            operation: operation,
            serviceType: serviceType,
            guards: guards,
            responseTransformers: responseTransformers
        )

        webService.addEndpoint(&endpoint, at: paths)
    }
    
    override func finishedRegistration() {
        super.finishedRegistration()
        
        webService.finish()
        
        app.logger.info(.init(stringLiteral: webService.root.debugDescription))

        if interfaceExporters.isEmpty {
            app.logger.warning("There aren't any Interface Exporters registered!")
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
            // before we run unnecessary export steps, we first verify that the Endpoint is indeed valid
            // in the case of not allowing lenient namespace definitions we just pass a empty array
            // which will result in the default namespace being used
            endpoint.parameterNameCollisionCheck(in: allowLenientParameterNamespaces ? I.parameterNamespace : .global)

            _ = endpoint.exportEndpoint(on: exporter)
        }
        
        for child in node.children {
            call(exporter: exporter, for: child)
        }
    }
    
    private func applicationInjectables(to guards: [LazyGuard]) -> [LazyGuard] {
        guards.map { lazyGuard in
            var `guard` = lazyGuard()
            `guard`.inject(app: app)
            return { `guard` }
        }
    }
    
    private func applicationInjectables(to responseTransformers: [LazyAnyResponseTransformer]) -> [LazyAnyResponseTransformer] {
        responseTransformers.map { lazyTransformer in
            var transformer = lazyTransformer()
            transformer.inject(app: app)
            return { transformer }
        }
    }
}


private protocol IdentifiableHandlerATRVisitorHelper: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = IdentifiableHandlerATRVisitorHelper
    associatedtype Input = IdentifiableHandler
    associatedtype Output
    func callAsFunction<T: IdentifiableHandler>(_ value: T) -> Output
}

private struct TestHandlerType: IdentifiableHandler {
    typealias Response = Never
    let handlerId = ScopedHandlerIdentifier<Self>("main")
}

extension IdentifiableHandlerATRVisitorHelper {
    @inline(never)
    @_optimize(none)
    fileprivate func _test() {
        _ = self(TestHandlerType())
    }
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
