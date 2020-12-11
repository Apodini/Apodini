//
// Created by Andi on 22.11.20.
//

import Vapor

class SharedSemanticModelBuilder: SemanticModelBuilder {
    private var interfaceExporters: [InterfaceExporter]
    var endpointsTreeRoot: EndpointsTreeNode?

    init(_ app: Application, interfaceExporters: InterfaceExporter.Type...) {
        self.interfaceExporters = interfaceExporters.map { exporterType in exporterType.init(app) }
        super.init(app)
    }

    override func register<C: Component>(component: C, withContext context: Context) {
        super.register(component: component, withContext: context)

        let operation = context.get(valueFor: OperationContextKey.self)
        var paths = context.get(valueFor: PathComponentContextKey.self)
        let guards = context.get(valueFor: GuardContextKey.self)
        let responseModifiers = context.get(valueFor: ResponseContextKey.self)

        let requestInjectables = component.extractRequestInjectables()

        var endpoint = Endpoint(
                description: String(describing: component),
                context: context,
                operation: operation,
                guards: guards,
                requestInjectables: requestInjectables,
                handleMethod: component.handle,
                responseTransformers: responseModifiers,
                handleReturnType: C.Response.self
        )

        if endpointsTreeRoot == nil {
            endpointsTreeRoot = EndpointsTreeNode(path: RootPath())
        }

        // "manually" add path components that are only defined as path parameters inside `Handler`s
        for parameter in endpoint.parameters {
            let pathDescription = ":\(parameter.id)"
            if parameter.parameterType == .path && !paths.contains(where: { ($0 as? _PathComponent)?.description == pathDescription }) {
                paths.append(pathDescription)
            }
        }
        // swiftlint:disable:next force_unwrapping
        endpointsTreeRoot!.addEndpoint(&endpoint, at: paths)
    }

    override func finishedProcessing() {
        super.finishedProcessing()

        guard let node = endpointsTreeRoot else {
            return
        }

        node.printTree() // currently only for debugging purposes

        for exporter in interfaceExporters {
            exporter.export(node)
        }
    }

    override func decode<T: Decodable>(_ type: T.Type, from request: Vapor.Request) throws -> T? {
        fatalError("Shared model is unable to deal with .decode")
    }
}
