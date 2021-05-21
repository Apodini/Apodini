//
// Created by Andreas Bauer on 22.11.20.
//

import NIO
@_implementationOnly import AssociatedTypeRequirementsVisitor

public class SemanticModelBuilder: InterfaceExporterVisitor {
    private(set) var app: Application

    var interfaceExporters: [AnyInterfaceExporter] = []
    /// This property (which is to be made configurable) toggles if the default `ParameterNamespace`
    /// (which is the strictest option possible) can be overridden by Exporters, which may allow more lenient
    /// restrictions. In the end the Exporter with the strictest `ParameterNamespace` will dictate the requirements
    /// towards parameter naming.
    private let allowLenientParameterNamespaces = true

    let webService: WebServiceModel
    let rootNode: EndpointsTreeNode

    var relationshipBuilder: RelationshipBuilder
    var typeIndexBuilder: TypeIndexBuilder
    
    private var onRegistrationDone: [() -> Void] = []

    init(_ app: Application) {
        self.app = app
        webService = WebServiceModel(GlobalBlackboard<LazyHashmapBlackboard>(app))
        rootNode = webService.root

        relationshipBuilder = RelationshipBuilder(logger: app.logger)
        typeIndexBuilder = TypeIndexBuilder(logger: app.logger)
    }

    /// Registers an `InterfaceExporter` instance on the model builder.
    /// - Parameter exporterType: The type of `InterfaceExporter` to register.
    /// - Returns: `Self`
    func with<T: InterfaceExporter>(exporter exporterType: T.Type) -> Self {
        let exporter = exporterType.init(app)
        interfaceExporters.append(AnyInterfaceExporter(exporter))
        return self
    }

    /// Registers an `StaticInterfaceExporter` instance on the model builder.
    /// - Parameter exporterType: The type of `StaticInterfaceExporter` to register.
    /// - Returns: `Self`
    func with<T: StaticInterfaceExporter>(exporter exporterType: T.Type) -> Self {
        let exporter = exporterType.init(app)
        interfaceExporters.append(AnyInterfaceExporter(exporter))
        return self
    }
    
    /// Registers an `InterfaceExporter` instance on the model builder.
    /// - Parameter instance: The instance to register.
    /// - Returns: `Self`
    public func with<T: InterfaceExporter>(exporter instance: T) -> Self {
        interfaceExporters.append(AnyInterfaceExporter(instance))
        return self
    }
    
    /// Registers an `AnyInterfaceExporter` instance on the model builder.
    /// - Parameter instance: The instance to register.
    /// - Returns: `Self`
    func with(export instance: AnyInterfaceExporter) -> Self {
        interfaceExporters.append(instance)
        return self
    }

    func register<H: Handler>(handler: H, withContext context: Context) {
        let handler = handler.inject(app: app)
        let guards = context.get(valueFor: GuardContextKey.self).allActiveGuards.inject(app: app)
        let responseTransformers = context.get(valueFor: ResponseTransformerContextKey.self).inject(app: app)
        
        // GlobalBlackboard's content lives on the app's `Store`, this is only a wrapper for accessing it
        let globalBlackboard = GlobalBlackboard<LazyHashmapBlackboard>(app)
        
        let localBlackboard = LocalBlackboard<
            LazyHashmapBlackboard,
            GlobalBlackboard<LazyHashmapBlackboard>
        >(globalBlackboard, using: handler, context)
        
        // We first only build the blackboards. The rest is executed at the beginning of `finishedRegistration`.
        // This way `.global` `KnowledgeSource`s get a complete view of the web service even when accessed from
        // an `Endpoint`.
        onRegistrationDone.append { [weak self] in
            guard let self = self else {
                return
            }
            
            let paths = context.get(valueFor: PathComponentContextKey.self)
            

            let partialCandidates = context.get(valueFor: RelationshipSourceCandidateContextKey.self)
            let relationshipSources = context.get(valueFor: RelationshipSourceContextKey.self)
            let relationshipDestinations = context.get(valueFor: RelationshipDestinationContextKey.self)

            var endpoint = Endpoint(
                handler: handler,
                blackboard: localBlackboard,
                guards: guards,
                responseTransformers: responseTransformers
            )

            self.webService.addEndpoint(&endpoint, at: paths)
            // The `ReferenceModule` and `EndpointPathModule` cannot be implemented using one of the standard
            // `KnowledgeSource` protocols as they depend on the `WebServiceModel`. This should change
            // once the latter was ported to the Blackboard-Pattern.
            endpoint[ReferenceModule.self].inject(reference: endpoint.reference)
            endpoint[EndpointPathModule.self].inject(absolutePath: endpoint.absolutePath)
            

            // calling the addEndpoint first, triggers the Operation uniqueness check
            // and we will have less problems with that in the TypeIndex Builder and Relationship Builders.
            // Additionally, addEndpoint may cause a insertion of a additional path parameter,
            // which makes it necessary to be called before any operation relying on the path of the Endpoint.

            self.relationshipBuilder.collect(
                endpoint: endpoint,
                candidates: partialCandidates,
                sources: relationshipSources,
                destinations: relationshipDestinations
            )
            
            let content = endpoint[HandleReturnType.self].type
            let reference = endpoint[ReferenceModule.self].reference
            let markedDefault = endpoint[Context.self].get(valueFor: DefaultRelationshipContextKey.self) != nil
            let pathParameters = endpoint[EndpointPathModule.self].absolutePath.listPathParameters()
            let operation = endpoint[Operation.self]
            
            self.typeIndexBuilder.indexContentType(content: content,
                                                   reference: reference,
                                                   markedDefault: markedDefault,
                                                   pathParameters: pathParameters,
                                                   operation: operation)
        }
    }

    func finishedRegistration() {
        onRegistrationDone.forEach { action in action() }
        
        webService.finish()

        // the order of how relationships are built below strongly reflect our strategy
        // on how conflicting definitions shadow each other
        let typeIndex = TypeIndex(from: typeIndexBuilder, buildingWith: relationshipBuilder)
        
        // resolving any type based Relationship creation (inference or Relationship DSL)
        typeIndex.resolve()

        // after we collected any relationships from the `typeIndex.resolve()` step
        // we can construct the final relationship model.
        relationshipBuilder.buildAll()

        app.logger.info("\(webService.debugDescription)")

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

            endpoint.exportEndpoint(on: exporter)
        }

        for child in node.children {
            call(exporter: exporter, for: child)
        }
    }
}

public struct SemanticModelBuilderKey: StorageKey {
    public typealias Value = SemanticModelBuilder
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
