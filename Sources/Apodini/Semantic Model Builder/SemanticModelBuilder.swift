//
// Created by Andreas Bauer on 22.11.20.
//

import NIO
@_implementationOnly import AssociatedTypeRequirementsVisitor

class SemanticModelBuilder: InterfaceExporterVisitor {
    private(set) var app: Application

    var interfaceExporters: [AnyInterfaceExporter] = []
    /// This property (which is to be made configurable) toggles if the default `ParameterNamespace`
    /// (which is the strictest option possible) can be overridden by Exporters, which may allow more lenient
    /// restrictions. In the end the Exporter with the strictest `ParameterNamespace` will dictate the requirements
    /// towards parameter naming.
    private let allowLenientParameterNamespaces = true
    
    var endpointsToExport: [_AnyEndpoint] = []

    init(_ app: Application) {
        self.app = app
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
    func with<T: InterfaceExporter>(exporter instance: T) -> Self {
        interfaceExporters.append(AnyInterfaceExporter(instance))
        return self
    }


    func register<H: Handler>(handler: H, withContext context: Context) {
        let handler = handler.inject(app: app)
        
        // GlobalBlackboard's content lives on the app's `Store`, this is only a wrapper for accessing it
        let globalBlackboard = GlobalBlackboard<LazyHashmapBlackboard>(app)
        
        let localBlackboard = LocalBlackboard<
            LazyHashmapBlackboard,
            GlobalBlackboard<LazyHashmapBlackboard>
        >(globalBlackboard, using: handler, context)
        
        // We first only build the blackboards and the `Endpoint`. The validation and exporting is done at the
        // beginning of `finishedRegistration`. This way `.global` `KnowledgeSource`s get a complete view of
        // the web service even when accessed from an `Endpoint`.
        endpointsToExport.append(Endpoint(
            handler: handler,
            blackboard: localBlackboard
        ))
    }

    func finishedRegistration() {
        if interfaceExporters.isEmpty {
            app.logger.warning("There aren't any Interface Exporters registered!")
        }

        interfaceExporters.acceptAll(self)
    }

    func visit<I>(exporter: I) where I: InterfaceExporter {
        call(exporter: exporter)
        exporter.finishedExporting(WebServiceModel(blackboard: GlobalBlackboard<LazyHashmapBlackboard>(app)))
    }

    func visit<I>(staticExporter: I) where I: StaticInterfaceExporter {
        call(exporter: staticExporter)
        staticExporter.finishedExporting(WebServiceModel(blackboard: GlobalBlackboard<LazyHashmapBlackboard>(app)))
    }

    private func call<I: BaseInterfaceExporter>(exporter: I) {
        for endpoint in endpointsToExport {
            // before we run unnecessary export steps, we first verify that the Endpoint is indeed valid
            // in the case of not allowing lenient namespace definitions we just pass a empty array
            // which will result in the default namespace being used
            endpoint.parameterNameCollisionCheck(in: allowLenientParameterNamespaces ? I.parameterNamespace : .global)

            endpoint.exportEndpoint(on: exporter)
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
