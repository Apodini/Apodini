//
// Created by Sadik Ekin Ozbay on 03.01.21.
//

@_implementationOnly import Vapor
@_implementationOnly import GraphQL
import Foundation

struct QueryInput: Codable {
    var query: String
}


class GraphQLInterfaceExporter: InterfaceExporter {
    // GraphQL Schema
    private var schema: GraphQLSchema?


    let app: Application
    let graphQLPath: GraphQLSchemaBuilder

    required init(_ app: Application) {
        graphQLPath = GraphQLSchemaBuilder()
        self.app = app
    }

    private func graphQLIDE(_ _: Vapor.Request) throws -> Vapor.Response {
        guard let htmlFile = Bundle.module.path(forResource: "graphql-ide", ofType: "html"),
              let html = try? String(contentsOfFile: htmlFile) else {
            throw Vapor.Abort(.internalServerError)
        }
        return Vapor.Response(status: .ok, headers: ["Content-Type": "text/html"], body: .init(string: html))
    }

    private func graphqlServer(_ req: Vapor.Request) throws -> EventLoopFuture<String> {
        guard let body = req.body.string,
              let data = body.data(using: .utf8) else {
            throw ApodiniError(type: .badInput, reason: "No body is given!")
        }

        let decoder = JSONDecoder()
        let input = try decoder.decode(QueryInput.self, from: data)
        let query = input.query

        if let genSchema = schema {
            return try graphql(schema: genSchema, request: query, context: req, eventLoopGroup: req.eventLoop).map { result -> String in
                result.description
            }
        } else {
            throw ApodiniError(type: .serverError, reason: "GraphQL schema creation error!")
        }
    }

    // We should have parameter for the result struct values and paramters
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        do {
            try graphQLPath.append(for: endpoint, with: endpoint.createConnectionContext(for: self))
        } catch {
            app.logger.log(level: .error, "Export error for \(endpoint)")
        }
    }

    func exportParameter<Type: Codable>(_ parameter: EndpointParameter<Type>) -> String {
        parameter.name
    }

    func finishedExporting(_ webService: WebServiceModel) {
        do {
            schema = try graphQLPath.generate()
        } catch {
            app.logger.log(level: .error, "Schema Creation Error!")
        }

        app.vapor.app.post("graphql", use: graphqlServer)
        app.vapor.app.get("graphql", use: graphQLIDE)
    }

    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: GraphQLRequest) throws -> Type?? {
        if let queryArgDict = request.args.dictionary,
           let val = queryArgDict[parameter.name] {
            if val.isNumber {
                return val.int as? Type
            } else if val.isString {
                return val.string as? Type
            }
            return nil
        }
        return nil
    }
}