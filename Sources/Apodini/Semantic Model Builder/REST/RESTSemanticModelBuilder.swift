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
        pathComponents
            .map { pathComponent in
                pathComponent.description
            }
            .joined(separator: "/")
    }
    
    
    init(_ pathComponents: [PathComponent]) {
        print("builder")
        print(pathComponents)
        for pathComponent in pathComponents {
            if let pathComponent = pathComponent as? _PathComponent {
                print(pathComponent)
                if let pathString = (pathComponent as? String), pathString.hasPrefix(":") {
                    print(pathString.components(separatedBy: ":")[1])
//                    pathComponents.append(.parameter(pathComponent))
//                    pathComponents.append(.parameter(pathString.components(separatedBy: ":")[1]))
                }
                pathComponent.append(to: &self)
            }
        }
    }
    
    
    mutating func append(_ string: String) {
        
        print("added " + string)
        if string.hasPrefix(":") {
            let component = string.components(separatedBy: ":")[1]
            pathComponents.append(.parameter(component))
        } else {
            let pathComponent = string.lowercased()
            pathComponents.append(.constant(pathComponent))
        }
    }
    
    mutating func append<T>(_ identifiier: Identifier<T>) where T: Identifiable {
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
        
        let requestHandler = context.createRequestHandler(withComponent: component, using: self)
        RESTPathBuilder(context.get(valueFor: PathComponentContextKey.self))
            .routesBuilder(app)
            .on(context.get(valueFor: HTTPMethodContextKey.self), [], use: requestHandler)
    }

    override func decode<T: Decodable>(_ type: T.Type, from request: Vapor.Request) throws -> T? {
        print("called")
        if let byteBuffer = request.body.data {
            print(byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes))
            let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes)
            request.body
            print(try JSONDecoder().decode(T.self, from: data!))
        }
        guard let byteBuffer = request.body.data, let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
            throw Vapor.Abort(.internalServerError, reason: "Could not read the HTTP request's body")
        }

        return try JSONDecoder().decode(type, from: data)
    }
    
    
    private func printRESTPath<C>(of component: C, withContext context: Context) where C: Component {
        let httpType = context.get(valueFor: HTTPMethodContextKey.self)
        
        let restPathBuilder = RESTPathBuilder(context.get(valueFor: PathComponentContextKey.self))
        
        let responseTransformerTypes = context.get(valueFor: ResponseContextKey.self)
        let returnType: ResponseEncodable.Type = {
            guard let lastResponseTransformerType = responseTransformerTypes.last else {
                return C.Response.self
            }
            return lastResponseTransformerType().transformedResponseType
        }()
        
        let guards = context.get(valueFor: GuardContextKey.self)
        
        app.logger.info("\(restPathBuilder.pathDescription) + \(httpType.rawValue) -> \(returnType) with \(guards.count) guards.")
    }
}
