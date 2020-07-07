//
//  RESTVisitor.swift
//  
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor


class RESTVisitor: Visitor {
    struct RESTPathBuilder: PathBuilder {
        var pathDescription: String {
            pathComponents.map { pathComponent in
                pathComponent.description
            }.joined(separator: "/")
        }
        var pathComponents: [Vapor.PathComponent] = []
        
        mutating func append(_ string: String) {
            let pathComponent = string.lowercased()
            pathComponents.append(.constant(pathComponent))
        }
        
        mutating func append<T>(_ identifiier: Identifier<T>) where T : Identifiable {
            let pathComponent = identifiier.identifier
            pathComponents.append(.parameter(pathComponent))
        }
    }
    
    override init(_ app: Application) {
        super.init(app)
    }
    
    public override func register<C>(component: C) where C: Component {
        super.register(component: component)
        
        var restPathBuilder = RESTPathBuilder()
        for pathComponent in getContextValue(for: PathComponentContextKey.self) {
            pathComponent.append(to: &restPathBuilder)
        }
        let httpType = getContextValue(for: HTTPMethodContextKey.self)
        let returnType: ResponseEncodable.Type = {
            let modifiedResponseType = getContextValue(for: ResponseContextKey.self)
            if modifiedResponseType != Never.self {
                return modifiedResponseType
            } else {
                return C.Response.self
            }
        }()

        print("\(restPathBuilder.pathDescription) \(httpType.rawValue) -> \(returnType)")
        
        let routesBuilder = restPathBuilder.pathComponents.reduce(app.routes.grouped([])) { routesBuilder, pathComponent in
            routesBuilder.grouped(pathComponent)
        }
        
        routesBuilder.on(HTTPMethod.init(rawValue: httpType.rawValue), []) { request in
            ""
        }
        
        super.finishedRegisteringContext()
    }
}
