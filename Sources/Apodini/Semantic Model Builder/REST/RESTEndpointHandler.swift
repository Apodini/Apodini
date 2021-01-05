//
// Created by Andi on 30.12.20.
//

import Foundation
@_implementationOnly import Vapor
import protocol FluentKit.Database

extension Vapor.Request: ExporterRequest, WithEventLoop, Reducible {}

struct ResponseContainer: Encodable, ResponseEncodable {
    var data: AnyEncodable?
    var links: [String: String]

    enum CodingKeys: String, CodingKey {
        case data = "data"
        case links = "_links"
    }

    init(_ data: AnyEncodable?, links: [String: String]) {
        self.data = data
        self.links = links
    }

    func encodeResponse(for request: Vapor.Request) -> EventLoopFuture<Response> {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]
        #warning("We may remove JSONEncoder .prettyPrinted in production or make it configurable in some way")

        let response = Response()
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
    var context: AnyConnectionContext<RESTInterfaceExporter>

    init(for endpoint: Endpoint<H>, with context: AnyConnectionContext<RESTInterfaceExporter>) {
        self.endpoint = endpoint
        self.context = context
    }

    func register(at routesBuilder: Vapor.RoutesBuilder, with operation: Operation) {
        routesBuilder.on(operation.httpMethod, [], use: self.handleRequest)
    }

    func handleRequest(request: Vapor.Request) -> EventLoopFuture<ResponseContainer> {
        let response = context.handle(request: request)

        // swiftlint:disable:next todo
        let uriPrefix = "http://127.0.0.1:8080/" // TODO resolve that somehow
        var links = ["self": uriPrefix + endpoint.absolutePath.joinPathComponents()]
        for relationship in endpoint.relationships {
            links[relationship.name] = uriPrefix + relationship.destinationPath.joinPathComponents()
        }

        return response.flatMapThrowing { encodableAction in
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
