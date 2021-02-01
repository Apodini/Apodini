//
// Created by Andi on 30.12.20.
//

import Foundation
import Apodini
@_implementationOnly import Vapor
import protocol FluentKit.Database

extension Vapor.Request: ExporterRequest, WithEventLoop {}

struct ResponseContainer: Encodable, ResponseEncodable {
    typealias Links = [String: String]
    var data: AnyEncodable?
    var links: Links

    enum CodingKeys: String, CodingKey {
        case data = "data"
        case links = "_links"
    }

    init(_ data: AnyEncodable?, links: [String: String]) {
        self.data = data
        self.links = links
    }

    func encodeResponse(for request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]

        let response = Vapor.Response()
        do {
            if data != nil {
                try response.content.encode(self, using: jsonEncoder)
            }
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
        return request.eventLoop.makeSucceededFuture(response)
    }
}

class RESTEndpointHandler<H: Handler> {
    let endpoint: Endpoint<H>
    var contextCreator: () -> AnyConnectionContext<RESTInterfaceExporter>
    let configuration: RESTConfiguration

    init(
        for endpoint: Endpoint<H>,
        using contextCreator: @escaping () -> AnyConnectionContext<RESTInterfaceExporter>,
        configuration: RESTConfiguration) {
        self.endpoint = endpoint
        self.contextCreator = contextCreator
        self.configuration = configuration
    }

    func register(at routesBuilder: Vapor.RoutesBuilder, with operation: Apodini.Operation) {
        routesBuilder.on(operation.httpMethod, [], use: self.handleRequest)
    }

    func handleRequest(request: Vapor.Request) -> EventLoopFuture<ResponseContainer> {
        var context = self.contextCreator()
        let response = context.handle(request: request)

        var links = ["self": configuration.uriPrefix + endpoint.absolutePath.asPathString()]
        for relationship in endpoint.relationships {
            links[relationship.name] = configuration.uriPrefix + relationship.destinationPath.asPathString()
        }

        return response.map { encodableAction in
            switch encodableAction {
            case let .send(element),
                 let .final(element):
                return ResponseContainer(element, links: links)
            case .nothing, .end:
                // nothing to encode,
                // so leave the response body empty
                return ResponseContainer(nil, links: links)
            }
        }
    }
}
