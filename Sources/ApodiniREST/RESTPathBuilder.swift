//
// Created by Andreas Bauer on 22.01.21.
//

import Apodini
import Vapor

struct RESTPathBuilder: PathBuilder {
    private var pathComponents: [Vapor.PathComponent] = []
    private var pathString: [String] = []
    var pathDescription: String {
        pathString.joined(separator: "/")
    }

    mutating func append(_ string: String) {
        pathComponents.append(.constant(string))
        pathString.append(string)
    }

    mutating func root() {
        pathString.append("")
    }

    mutating func append<Type>(_ parameter: EndpointPathParameter<Type>) {
        pathComponents.append(.parameter(parameter.pathId))
        pathString.append("{\(parameter.name)}")
    }

    func routesBuilder(_ app: Vapor.Application) -> Vapor.RoutesBuilder {
        app.routes.grouped(pathComponents)
    }
}
