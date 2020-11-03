//
//  RESTSemanticModelBuilder.swift
//  
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor


struct RESTPathBuilder: PathBuilder {
    private var pathComponents: [Vapor.PathComponent] = []
    
    
    fileprivate var pathDescription: String {
        pathComponents.map { pathComponent in
            pathComponent.description
        }.joined(separator: "/")
    }
    
    
    init(_ pathComponents: [PathComponent]) {
        for pathComponent in pathComponents {
            if let pathComponent = pathComponent as? _PathComponent {
                pathComponent.append(to: &self)
            }
        }
    }
    
    
    mutating func append(_ string: String) {
        let pathComponent = string.lowercased()
        pathComponents.append(.constant(pathComponent))
    }
    
    mutating func append<T>(_ identifiier: Identifier<T>) where T : Identifiable {
        let pathComponent = identifiier.identifier
        pathComponents.append(.parameter(pathComponent))
    }
    
    func routesBuilder(_ app: Vapor.Application) -> Vapor.RoutesBuilder {
        app.routes.grouped(pathComponents)
    }
}


class RESTSemanticModelBuilder: SemanticModelBuilder {
    override init(_ app: Application) {
        super.init(app)
    }
    
    override func register<C>(component: C, withContext context: Context) where C: Component {
        super.register(component: component, withContext: context)
        
        
        #if DEBUG
        self.printRESTPath(of: component, withContext: context)
        #endif
        
        // Note:
        // We currently just register the component here using the functionality based of Vapor.
        // The next step would be to create a sophisticated semantic model based on the Context and Components and use this to register the components in a structured way and e.g. provide HATEOS information.
        
        let requestHandler = context.createRequestHandler(withComponent: component)
        RESTPathBuilder(context.get(valueFor: PathComponentContextKey.self))
            .routesBuilder(app)
            .on(context.get(valueFor: HTTPMethodContextKey.self), [], use: requestHandler)
    }
    
    
    private func printRESTPath<C>(of component: C, withContext context: Context) where C: Component {
        let httpType = context.get(valueFor: HTTPMethodContextKey.self)
        
        let restPathBuilder = RESTPathBuilder(context.get(valueFor: PathComponentContextKey.self))
        
        let responseTransformerTypes = context.get(valueFor: ResponseContextKey.self)
        let returnType: ResponseEncodable.Type = {
            if responseTransformerTypes.isEmpty {
                return C.Response.self
            } else {
                return responseTransformerTypes.last!().transformedResponseType
            }
        }()
        
        let guards = context.get(valueFor: GuardContextKey.self)
        
        app.logger.info("\(restPathBuilder.pathDescription) + \(httpType.rawValue) -> \(returnType) with \(guards.count) guards.")
    }
}
