//
// Created by Andi on 30.12.20.
//

import Foundation
@_implementationOnly import Vapor
import protocol FluentKit.Database

extension Vapor.Request: ExporterRequest, WithEventLoop, WithDatabase {
    var database: () -> Database {{
        self.db
    }}
}

struct ResponseContainer: Encodable, ResponseEncodable {
    var data: AnyEncodable
    var links: [String: String]

    enum CodingKeys: String, CodingKey {
        case data = "data"
        case links = "_links"
    }

    init(_ data: Encodable, links: [String: String]) {
        self.data = AnyEncodable(value: data)
        self.links = links
    }

    func encodeResponse(for request: Vapor.Request) -> EventLoopFuture<Response> {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]
        #warning("We may remove JSONEncoder .prettyPrinted in production or make it configurable in some way")

        let response = Response()
        do {
            try response.content.encode(self, using: jsonEncoder)
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
        return request.eventLoop.makeSucceededFuture(response)
    }
}

struct RESTEndpointHandler<H: Handler> {
    let endpoint: Endpoint<H>
    let requestHandler: EndpointRequestHandler<RESTInterfaceExporter>

    init(for endpoint: Endpoint<H>, with requestHandler: EndpointRequestHandler<RESTInterfaceExporter>) {
        self.endpoint = endpoint
        self.requestHandler = requestHandler
    }

    func register(at routesBuilder: Vapor.RoutesBuilder, with operation: Operation) {
        routesBuilder.on(operation.httpMethod, [], use: self.handleRequest)
    }

    func handleRequest(request: Vapor.Request) -> EventLoopFuture<ResponseContainer> {
        let response = requestHandler(request: request)

        // swiftlint:disable:next todo
        let uriPrefix = "http://127.0.0.1:8080/" // TODO resolve that somehow
        var links = ["self": uriPrefix + endpoint.absolutePath.joinPathComponents()]
        for relationship in endpoint.relationships {
            links[relationship.name] = uriPrefix + relationship.destinationPath.joinPathComponents()
        }

        return response.flatMapThrowing { encodable in
            ResponseContainer(encodable, links: links)
        }
    }
}
