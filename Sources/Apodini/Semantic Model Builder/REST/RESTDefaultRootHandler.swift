//
// Created by Andreas Bauer on 22.01.21.
//

@_implementationOnly import Vapor

/// A RoutesHandler which is automatically registered to the root path
/// if there is no Endpoint registered under the root, in order to server entry point links.
struct RESTDefaultRootHandler {
    let configuration: RESTConfiguration
    let relationships: Set<RelationshipDestination>

    // Registers a GET handler on root path
    func register(on app: Vapor.Application) {
        app.get(use: self.handleRequest)
    }

    func handleRequest(_: Vapor.Request) -> ResponseContainer {
        ResponseContainer(
            Empty.self,
            links: relationships.formatRelationships(into: [:], with: LinksFormatter(configuration: configuration))
        )
    }
}
