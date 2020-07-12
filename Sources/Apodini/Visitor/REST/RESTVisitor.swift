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
    
    override func register<C>(component: C) where C: Component {
        super.register(component: component)
        
        var restPathBuilder = RESTPathBuilder()
        for pathComponent in getContextValue(for: PathComponentContextKey.self) {
            if let pathComponent = pathComponent as? _PathComponent {
                pathComponent.append(to: &restPathBuilder)
            }
        }
        let httpType = getContextValue(for: HTTPMethodContextKey.self)
        let responseTransformerTypes = getContextValue(for: ResponseContextKey.self)
        let returnType: ResponseEncodable.Type = {
            if responseTransformerTypes.isEmpty {
                return C.Response.self
            } else {
                return responseTransformerTypes.last!().transformedResponseType
            }
        }()
        
        let guards = currentNode.getContextValue(for: GuardContextKey.self)
        
        print("\(restPathBuilder.pathDescription) \(httpType.rawValue) -> \(returnType)")
        
        let routesBuilder = restPathBuilder.pathComponents.reduce(app.routes.grouped([])) { routesBuilder, pathComponent in
            routesBuilder.grouped(pathComponent)
        }
        
        routesBuilder.on(HTTPMethod.init(rawValue: httpType.rawValue), []) { request -> EventLoopFuture<Vapor.Response> in
            let guardEventLoopFutures = guards.map { requestGuard in
                requestGuard().check(request)
            }
            return EventLoopFuture<Void>
                .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
                .flatMap { _ in
                    request.enterRequestContext(with: component) { component in
                        var response: ResponseEncodable = component.handle()
                        for responseTransformer in responseTransformerTypes {
                            response = responseTransformer().transform(response: response)
                        }
                        return response.encodeResponse(for: request)
                    }
                }
        }
        
        super.finishedRegisteringContext()
    }
}
