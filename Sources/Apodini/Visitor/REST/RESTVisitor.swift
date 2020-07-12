//
//  RESTVisitor.swift
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
        pathComponents
            .reduce(app.routes.grouped([])) { routesBuilder, pathComponent in
                routesBuilder.grouped(pathComponent)
            }
    }
}


class RESTVisitor: Visitor {
    override init(_ app: Application) {
        super.init(app)
    }
    
    override func register<C: Component>(component: C) {
        super.register(component: component)
        
        #if DEBUG
        self.printRESTPath(of: component)
        #endif
        
        let requestHandler = createRequestHandler(withComponent: component)
        RESTPathBuilder(getContextValue(for: PathComponentContextKey.self))
            .routesBuilder(app)
            .on(getContextValue(for: HTTPMethodContextKey.self), [], use: requestHandler)
        
        super.finishedRegisteringContext()
    }
    
    
    private func printRESTPath<C: Component>(of component: C) {
        let httpType = getContextValue(for: HTTPMethodContextKey.self)
        
        let restPathBuilder = RESTPathBuilder(getContextValue(for: PathComponentContextKey.self))
        
        let responseTransformerTypes = getContextValue(for: ResponseContextKey.self)
        let returnType: ResponseEncodable.Type = {
            if responseTransformerTypes.isEmpty {
                return C.Response.self
            } else {
                return responseTransformerTypes.last!().transformedResponseType
            }
        }()
        
        let guards = getContextValue(for: GuardContextKey.self)
        
        print("\(restPathBuilder.pathDescription) + \(httpType.rawValue) -> \(returnType) with \(guards.count) guards.")
    }
}
