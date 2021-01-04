//
// Created by Sadik Ekin Ozbay on 03.01.21.
//

import Fluent
@_implementationOnly import Vapor
import GraphQL
import NIO

enum HandleReturnType {
    case String
}

class GraphQLSchemaBuilder {
    //    private var heads = [String]()
//    private var idNameMapper = [String: String]()
    private var tree = [String: Set<String>]()
    private var leafHandler = [String: Encodable]()
    private var hasIncomingEdge = Set<String>()


    // GraphQL Related values
    private var types = [String: GraphQLObjectType]()
    private var fields = [String: GraphQLField]()


    init() {

    }

    func getTree() -> [String: Set<String>] {
        tree
    }

    private func graphQLFieldCreator(_ name: String, _ handler: Encodable) -> GraphQLField {
        switch handler {
        case let value as String:
            return GraphQLField(type: GraphQLString, resolve: { _, args, context, info in
                value
            })
        default:
            return GraphQLField(type: GraphQLString, resolve: { source, args, context, info in

                struct SecretError: Error, CustomStringConvertible {
                    let description: String
                }

                throw SecretError(description: "The type is not supported!")
            })
        }
    }

    private func appendSinglePoint(_ name: String, _ handler: Encodable) {
        self.fields[name] = self.graphQLFieldCreator(name, handler)
    }


    // Generated adjacency list tree
    func append<H: Handler>(_ endpoint: Endpoint<H>) {
        var currentPath = endpoint.absolutePath.map {
            $0.description.lowercased()
        }

        currentPath.removeFirst()
        // Handle Single points
        if (currentPath.count == 1) {
            self.appendSinglePoint(currentPath[0], endpoint.handler.handle())
            return
        }
        // Create node names
        var currentSum = String()
        for ix in 0..<currentPath.count {
            currentSum.append(currentPath[ix])
            currentSum.append("_")
            currentPath[ix] = currentSum
        }
        // Get leaf name
        let leafName = currentPath.last ?? "None"

        // Create handler
        self.leafHandler[leafName] = endpoint.handler.handle()

        // Create tree
        var indx = currentPath.count - 1
        while (indx >= 1) {
            let child = currentPath[indx], parent = currentPath[indx - 1]
            if (self.tree.keys.contains(parent)) {
                self.tree[parent]!.insert(child)
            } else {
                self.tree[parent] = [child]
            }
            hasIncomingEdge.insert(child)
            indx -= 1
        }

        print(self.tree)
        print(self.leafHandler)
        print("->", self.hasIncomingEdge)

    }

    private func generateSchemaFromTreeHelper(_ node: String) -> GraphQLField {
        let nodeName = node.components(separatedBy: "_").filter({ $0 != "" }).last ?? "None"
        if let childrenList = self.tree[node] {
            var currentFields = [String: GraphQLField]()
            for child in childrenList {
                let childName = child.components(separatedBy: "_").filter({ $0 != "" }).last ?? "None"
                currentFields[childName] = generateSchemaFromTreeHelper(child)
            }
            self.types[nodeName] = try! GraphQLObjectType(name: nodeName, fields: currentFields)
            // Mid Point Field. Resolve might be useless
            return GraphQLField(type: self.types[nodeName]!, resolve: { _, args, context, info in
                nodeName
            })
        } else {
            return self.graphQLFieldCreator(nodeName, self.leafHandler[node] ?? "Handler Error")
        }
    }

    private func generateSchemaFromTree() {
        for (parent, _) in self.tree {
            // It is one of the roots
            if (!self.hasIncomingEdge.contains(parent)) {
                let parentName = parent.components(separatedBy: "_").filter({ $0 != "" }).last ?? "None"
                self.fields[parentName] = generateSchemaFromTreeHelper(parent)
            }
        }
    }

    func generate() -> GraphQLSchema {
        self.generateSchemaFromTree()
        let queryType = try! GraphQLObjectType(
                name: "Apodini",
                fields: self.fields
        )
        return try! GraphQLSchema(
                query: queryType,
                types: Array(self.types.values)
        )
    }
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

        print("The query is", query)
        return try graphql(schema: self.schema,
                request: query,
                eventLoopGroup: req.eventLoop).map { result -> String in
            result.description
        }

    }

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        self.graphQLPath.append(endpoint)
    }

    func exportParameter<Type: Codable>(_ parameter: EndpointParameter<Type>) -> String {
        print("This is exportParameter")
        return "HI"
    }

    func finishedExporting(_ webService: WebServiceModel) {
        self.schema = self.graphQLPath.generate()
        print("This is finishedExporting")
    }

    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Vapor.Request) throws -> Type?? {
        print("This is retrieveParameter")
        switch parameter.parameterType {
        case .lightweight:
            // Note: Vapor also supports decoding into a struct which holds all query parameters. Though we have the requirement,
            //   that .lightweight parameter types conform to LosslessStringConvertible, meaning our DSL doesn't allow for that right now

            guard let query = request.query[Type.self, at: parameter.name] else {
                return nil // the query parameter doesn't exists
            }
            return query
        case .path:
            guard let stringParameter = request.parameters.get(parameter.pathId) else {
                return nil // the path parameter didn't exist on that request
            }
            guard let losslessStringParameter = parameter as? LosslessStringConvertibleEndpointParameter else {
                #warning("Must be replaced with a proper error to encode a response to the user")
                fatalError("Encountered .path Parameter which isn't type of LosslessStringConvertible!")
            }

            guard let value = losslessStringParameter.initFromDescription(description: stringParameter, type: Type.self) else {
                #warning("Must be replaced with a proper error to encode a response to the user")
                fatalError("""
                           Parsed a .path Parameter, but encountered invalid format when initializing LosslessStringConvertible!
                           Could not init \(Type.self) for string value '\(stringParameter)'
                           """)
            }
            return value
        case .content:
            guard request.body.data != nil else {
                // If the request doesn't have a body, there is nothing to decide.
                return nil
            }

            #warning("""
                     A Handler could define multiple .content Parameters. In such a case the REST exporter would
                     need to decode the content via a struct containing those .content parameters as properties.
                     This is currently unsupported.
                     """)

            return try request.content.decode(Type.self, using: JSONDecoder())
        }
    }
}