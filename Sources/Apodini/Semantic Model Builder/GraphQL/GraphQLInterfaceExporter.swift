//
// Created by Sadik Ekin Ozbay on 03.01.21.
//

@_implementationOnly import Vapor
import GraphQL

enum NetworkError: Error {
    case unauthorised
    case timeout
    case serverError
    case invalidResponse
    case noBody
}


class GraphQLInterfaceExporter: InterfaceExporter {


    // GraphQL Schema
    private var schema = try! GraphQLSchema(
            query: GraphQLObjectType(
                    name: "Apodini",
                    fields: [
                        "test": GraphQLField(
                                type: GraphQLString,
                                resolve: { _, _, _, _ in
                                    "It is working!"
                                }
                        )
                    ]
            )
    )


    let app: Application
    let graphQLPath: GraphQLSchemaBuilder

    required init(_ app: Application) {
        self.graphQLPath = GraphQLSchemaBuilder()
        self.app = app

        // For Query
        app.post("graphql", use: graphql_server)

        // TODO: app.get("graphql") -> For graphql interface
    }


    private func graphql_server(_ req: Vapor.Request) throws -> EventLoopFuture<String> {
        guard let body = req.body.string else {
            throw NetworkError.noBody
        }

        // Create Swift dict
        var query = "{}"
        let data = body.data(using: .utf8)!
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                if let q = jsonArray["query"] as? String {
                    query = q
                } else {
                    print("jsonArray doesn't have query parameter")
                }

            } else {
                print("bad json")
                throw NetworkError.noBody
            }
        } catch let error as NSError {
            print(error)
            throw NetworkError.noBody
        }

        return try graphql(schema: self.schema,
                request: query,
                context: req,
                eventLoopGroup: req.eventLoop).map { result -> String in
            result.description
        }

    }

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        self.graphQLPath.append(for: endpoint, with: endpoint.createConnectionContext(for: self))
    }

    func exportParameter<Type: Codable>(_ parameter: EndpointParameter<Type>) -> String {
        parameter.name
    }

    func finishedExporting(_ webService: WebServiceModel) {
        self.schema = self.graphQLPath.generate()
    }

    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: GraphQLRequest) throws -> Type?? {
        if let queryArgDict = request.args.dictionary,
           let val = queryArgDict[parameter.name] {

            if (val.isNumber) {
                return val.int as? Type
            } else if (val.isString) {
                return val.string as? Type
            }
            return nil
        }
        return nil
    }
}