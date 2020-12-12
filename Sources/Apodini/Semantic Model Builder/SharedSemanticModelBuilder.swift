//
// Created by Andi on 22.11.20.
//

import Vapor

class WebServiceModel {
    fileprivate let root: EndpointsTreeNode = EndpointsTreeNode(path: RootPath())
    fileprivate var finishedParsing = false

    lazy var rootEndpoints: [Endpoint] = {
        if !finishedParsing {
            fatalError("rootEndpoints of the WebServiceModel was accessed before parsing was finished!")
        }
        return root.endpoints.map { _, endpoint -> Endpoint in endpoint }
    }()
    var relationships: [EndpointRelationship] {
        root.relationships
    }

    fileprivate func addEndpoint(_ endpoint: inout Endpoint, at paths: [PathComponent]) {
        root.addEndpoint(&endpoint, at: paths)
    }
}

class SharedSemanticModelBuilder: SemanticModelBuilder {
    private var interfaceExporters: [InterfaceExporter]

    var webService: WebServiceModel

    init(_ app: Application, interfaceExporters: InterfaceExporter.Type...) {
        self.interfaceExporters = interfaceExporters.map { exporterType in exporterType.init(app) }
        webService = WebServiceModel()

        super.init(app)
    }

    override func register<C: Component>(component: C, withContext context: Context) {
        super.register(component: component, withContext: context)

        let operation = context.get(valueFor: OperationContextKey.self)
        var paths = context.get(valueFor: PathComponentContextKey.self)
        let guards = context.get(valueFor: GuardContextKey.self)
        let responseModifiers = context.get(valueFor: ResponseContextKey.self)

        let requestInjectables = component.extractRequestInjectables()

        let parameterBuilder = ParameterBuilder(from: requestInjectables)
        parameterBuilder.build()

        var endpoint = Endpoint(
                description: String(describing: component),
                context: context,
                operation: operation,
                guards: guards,
                requestInjectables: requestInjectables,
                handleMethod: component.handle,
                responseTransformers: responseModifiers,
                handleReturnType: C.Response.self,
                parameters: parameterBuilder.parameters
        )

        for parameter in endpoint.parameters {
            let pathDescription = ":\(parameter.id)"
            if parameter.parameterType == .path && !paths.contains(where: { ($0 as? _PathComponent)?.description == pathDescription }) {
                paths.append(pathDescription)
            }
        }

        webService.addEndpoint(&endpoint, at: paths)
    }

    override func finishedRegistration() {
        super.finishedRegistration()

        webService.finishedParsing = true

        webService.root.printTree() // currently only for debugging purposes

        for exporter in interfaceExporters {
            call(exporter: exporter, for: webService.root)
            exporter.finishedExporting(webService)
        }
    }

    private func call(exporter: InterfaceExporter, for node: EndpointsTreeNode) {
        for (_, endpoint) in node.endpoints {
            exporter.export(endpoint)
        }

        for child in node.children {
            call(exporter: exporter, for: child)
        }
    }

    override func decode<T: Decodable>(_ type: T.Type, from request: Vapor.Request) throws -> T? {
        fatalError("Shared model is unable to deal with .decode")
    }
}
