//
// Created by Andi on 22.11.20.
//

import NIO
@_implementationOnly import Vapor

typealias RequestHandler = (Request) -> EventLoopFuture<Encodable>

class WebServiceModel {
    fileprivate let root = EndpointsTreeNode(path: RootPath())
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
    
    
    override func register<C: Handler>(component: C, withContext context: Context) {
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
        
        let requestHandler = SharedSemanticModelBuilder.createRequestHandler(with: component, guards: guards, responseModifiers: responseModifiers)
        
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
            requestHandler: requestHandler,
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
    

    static func createRequestHandler<H: Handler>(
        with handler: H,
        guards: [LazyGuard] = [],
        responseModifiers: [() -> (AnyResponseTransformer)] = []
    ) -> RequestHandler
    {
        { (request: Request) in
            let guardEventLoopFutures = guards.map { guardClosure in
                request.enterRequestContext(with: guardClosure()) { requestGuard in
                    requestGuard.executeGuardCheck(on: request)
                }
            }
            return EventLoopFuture<Void>
                .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
                .flatMap { _ in
                    request.enterRequestContext(with: handler) { handler in
                        var response: Encodable = handler.handle()
                        for responseTransformer in responseModifiers {
                            response = request.enterRequestContext(with: responseTransformer()) { responseTransformer in
                                responseTransformer.transform(response: response)
                            }
                        }
                        return request.eventLoop.makeSucceededFuture(response)
                    }
                }
        }
    }
}
