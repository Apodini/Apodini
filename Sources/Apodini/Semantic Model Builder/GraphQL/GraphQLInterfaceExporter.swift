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


    let app: Vapor.Application
    let graphQLPath: GraphQLSchemaBuilder

    required init(_ app: Application) {
        self.graphQLPath = GraphQLSchemaBuilder()
        self.app = app.vapor.app

        // For Query
        self.app.post("graphql", use: self.graphqlServer)
        self.app.get("graphql", use: self.graphQLIDE)
    }

    private func graphQLIDE(_ _: Vapor.Request) -> Vapor.Response {
        let html: Vapor.Response.Body = """
                                        <html>
                                          <head>
                                            <title>GraphiQL</title>
                                            <link href="https://unpkg.com/graphiql/graphiql.min.css" rel="stylesheet" />
                                          </head>
                                          <body style="margin: 0;">
                                            <div id="graphiql" style="height: 100vh;"></div>
                                            <script
                                              crossorigin
                                              src="https://unpkg.com/react/umd/react.production.min.js"
                                            ></script>
                                            <script
                                              crossorigin
                                              src="https://unpkg.com/react-dom/umd/react-dom.production.min.js"
                                            ></script>
                                            <script
                                              crossorigin
                                              src="https://unpkg.com/graphiql/graphiql.min.js"
                                            ></script>
                                            <script>
                                              const graphQLFetcher = graphQLParams =>
                                                fetch('/graphql', {
                                                  method: 'post',
                                                  headers: { 'Content-Type': 'application/json' },
                                                  body: JSON.stringify(graphQLParams),
                                                })
                                                  .then(response => response.json())
                                                  .catch(() => response.text());
                                              ReactDOM.render(
                                                React.createElement(GraphiQL, { fetcher: graphQLFetcher }),
                                                document.getElementById('graphiql'),
                                              );
                                            </script>
                                          </body>
                                        </html>
                                        """

        return Vapor.Response(status: .ok, headers: ["Content-Type": "text/html"], body: html)
    }

    private func graphqlServer(_ req: Vapor.Request) throws -> EventLoopFuture<String> {
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

    // We should have parameter for the result struct values and paramters
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