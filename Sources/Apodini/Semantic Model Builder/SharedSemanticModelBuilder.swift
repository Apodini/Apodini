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
    var rootNode: EndpointsTreeNode

    init(_ app: Application, interfaceExporters: InterfaceExporter.Type...) {
        self.interfaceExporters = interfaceExporters.map { exporterType in exporterType.init(app) }
        webService = WebServiceModel()
        rootNode = webService.root // used to provide the unit test a reference to the root of the tree

        super.init(app)
    }

    override func register<C: Component>(component: C, withContext context: Context) {
        super.register(component: component, withContext: context)

        let operation = context.get(valueFor: OperationContextKey.self)
        var paths = context.get(valueFor: PathComponentContextKey.self)
        let guards = context.get(valueFor: GuardContextKey.self)
        let responseModifiers = context.get(valueFor: ResponseContextKey.self)

        let parameterBuilder = ParameterBuilder(from: component)
        parameterBuilder.build()

        for parameter in parameterBuilder.parameters {
            if parameter.parameterType == .path && !paths.contains(where: { ($0 as? _PathComponent)?.description == ":\(parameter.id)" }) {
                if let pathComponent = parameterBuilder.requestInjectables[parameter.label] as? _PathComponent {
                    paths.append(pathComponent)
                }
            }
        }

        let requestHandlerBuilder = SharedSemanticModelBuilder.createRequestHandlerBuilder(with: component, guards: guards, responseModifiers: responseModifiers)

        let handleReturnType = C.Response.self
        var responseType: Encodable.Type {
            guard let lastResponseTransformer = responseModifiers.last else {
                return handleReturnType
            }
            return lastResponseTransformer().transformedResponseType
        }

        var endpoint = Endpoint(
                description: String(describing: component),
                context: context,
                operation: operation,
                requestHandlerBuilder: requestHandlerBuilder,
                handleReturnType: C.Response.self,
                responseType: responseType,
                parameters: parameterBuilder.parameters
        )

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

    override func encode<T: Encodable>(_ value: T, request: Vapor.Request) throws -> EventLoopFuture<Vapor.Response> {
        fatalError("Shared model is unable to deal with .encode")
    }

    static func createRequestHandlerBuilder<C: Component>(with component: C, guards: [LazyGuard] = [], responseModifiers: [() -> (AnyResponseTransformer)] = []) -> (RequestInjectableDecoder & ResponseEncoder) -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        { (coder: RequestInjectableDecoder & ResponseEncoder) in
            { (request: Vapor.Request) in
                let guardEventLoopFutures = guards.map { guardClosure in
                    request.enterRequestContext(with: guardClosure(), using: coder) { requestGuard in
                        requestGuard.executeGuardCheck(on: request)
                    }
                }
                return EventLoopFuture<Void>
                        .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
                        .flatMap { _ in
                            request.enterRequestContext(with: component, using: coder) { component in
                                var response: Encodable = component.handle()
                                for responseTransformer in responseModifiers {
                                    response = request.enterRequestContext(with: responseTransformer(), using: coder) { responseTransformer in
                                        responseTransformer.transform(response: response)
                                    }
                                }
                                return try! coder.encode(AnyEncodable(value: response), request: request)
                            }
                        }
            }
        }
    }
}
