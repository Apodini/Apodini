//
// Created by Sadik Ekin Ozbay on 06.01.21.
//

@_implementationOnly import Vapor
import GraphQL

// GraphQL EventLoop return handler
let GraphQLEventLoop = try! GraphQLScalarType(
        name: "EventLoop",
        description:
        "The `EventLoop(String)` scalar type represents textual data, represented as UTF-8 " +
                "character sequences. The String type is most often used by GraphQL to " +
                "represent free-form human-readable text.",
        serialize: { val in
            var res = String()
            // TODO: It does work but why ?
            (val as! EventLoopFuture<String>).whenSuccess { s in
                res = s
            }
            return try map(from: res)
        },
        parseValue: {
            print("parseValue->", type(of: $0), $0)
            return try .string($0.stringValue(converting: true))
        },
        parseLiteral: { ast in
            print("parseLiteral->", type(of: ast), ast)
            if let ast = ast as? StringValue {
                return .string(ast.value)
            }

            return .null
        }
)

func graphqlTypeMap(with type: Codable.Type) -> GraphQLScalarType {
    if (type == String.self) {
        return GraphQLString
    } else if (type == Int.self) {
        return GraphQLInt
    } else if (type == Float.self) {
        return GraphQLFloat
    } else if (type == Bool.self) {
        return GraphQLBoolean
    }
    return GraphQLString

}

struct GraphQLRequest: ExporterRequest {
    var source: Any
    var args: Map
    var context: Any
    var info: GraphQLResolveInfo
}


struct GraphQLResponseContainer: Encodable {
    var data: AnyEncodable?

    init(_ data: AnyEncodable?) {
        self.data = data
    }

    func encodeResponse() -> String {
        if let stringData = data?.value as? String {
            return stringData
        }

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        var response = String()
        do {
            if let currentData = self.data {
                print("Current data is ", currentData.value)
                let encodedData = try jsonEncoder.encode(currentData)
                response = String(data: encodedData, encoding: .utf8)!
            }
        } catch {
            response = "Error happened in the data encoding!"
        }
        return response
    }
}

class GraphQLSchemaBuilder {
    private var tree = [String: Set<String>]()
    private var leafHandler = [String: AnyConnectionContext<GraphQLInterfaceExporter>]()
    private var leafHandlerResponseType = [String: Encodable.Type]()
    private var hasIncomingEdge = Set<String>()


    // GraphQL Related values
    private var types = [String: GraphQLObjectType]()
    private var fields = [String: GraphQLField]()
    private var args = [String: [String: GraphQLArgument]]()

    private func graphQLFieldCreator(for responseType: Encodable.Type, with context: AnyConnectionContext<GraphQLInterfaceExporter>, with args: [String: GraphQLArgument]) -> GraphQLField {
        var mutableContext = context
        return GraphQLField(type: GraphQLEventLoop, args: args, resolve: { gSource, gArgs, gContext, gInfo in
            let request = GraphQLRequest(source: gSource, args: gArgs, context: gContext, info: gInfo)
            let vaporRequest = gContext as! Vapor.Request
            let response: EventLoopFuture<Action<AnyEncodable>> = mutableContext.handle(request: request, eventLoop: vaporRequest.eventLoop.next())

            let res = response.flatMapThrowing { encodableAction -> String in
                switch encodableAction {
                case let .send(element),
                     let .final(element):
                    return GraphQLResponseContainer(element).encodeResponse()
                case .nothing, .end:
                    return "EMPTY?"
                }
            }

            return res
        })
    }

    // Generated adjacency list tree
    func append<H: Handler>(for endpoint: Endpoint<H>, with context: AnyConnectionContext<GraphQLInterfaceExporter>) {
        var currentPath = endpoint.absolutePath.map {
            $0.description.lowercased()
        }.filter {
            $0.first != ":"
        }

        // TODO: Does starting ":" indicate Parameter? Because it is in the path
        // TODO: e.g. ->> ["v1", "user", ":1234-asdf-12341234"]
        currentPath.removeFirst()

        // Create node names
        var currentSum = String()
        if (currentPath.count > 1) {
            for ix in 0..<currentPath.count {
                currentSum.append(currentPath[ix])
                currentSum.append("_")
                currentPath[ix] = currentSum
            }
        }

        // Get leaf name
        let leafName = currentPath.last ?? "None"
        for p in endpoint.parameters {
            let graphqlType = graphqlTypeMap(with: p.propertyType)
            if (p.necessity == .required) {
                self.args[leafName, default: [:]][p.name] = GraphQLArgument(type: GraphQLNonNull(graphqlType), description: p.description)
            } else {
                self.args[leafName, default: [:]][p.name] = GraphQLArgument(type: graphqlType, description: p.description)
            }

        }

        // Handle Single points
        if (currentPath.count == 1) {
            self.fields[leafName] = self.graphQLFieldCreator(for: endpoint.responseType, with: context, with: self.args[leafName] ?? [:])
            return
        }

        // Create handler
        self.leafHandler[leafName] = context
        self.leafHandlerResponseType[leafName] = endpoint.responseType

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


    }

    private func nameExtractor(for node: String) -> String {
        node.components(separatedBy: "_").filter({ $0 != "" }).last ?? "None"
    }

    private func generateSchemaFromTreeHelper(_ node: String) -> GraphQLField {
        let nodeName = self.nameExtractor(for: node)
        if let childrenList = self.tree[node] {
            var currentFields = [String: GraphQLField]()
            for child in childrenList {
                let childName = child.components(separatedBy: "_").filter({ $0 != "" }).last ?? "None"
                currentFields[childName] = generateSchemaFromTreeHelper(child)
            }
            self.types[nodeName] = try! GraphQLObjectType(name: nodeName, fields: currentFields)

            return GraphQLField(type: self.types[nodeName]!, resolve: { _, _, _, _ in "Emtpy" })
        } else {
            return self.graphQLFieldCreator(for: self.leafHandlerResponseType[node]!, with: self.leafHandler[node]!, with: self.args[node] ?? [:])
        }
    }

    private func generateSchemaFromTree() {
        for (parent, _) in self.tree {
            // It is one of the roots
            if (!self.hasIncomingEdge.contains(parent)) {
                let parentName = self.nameExtractor(for: parent)
                self.fields[parentName] = generateSchemaFromTreeHelper(parent)
            }
        }
    }

    func generate() -> GraphQLSchema {
        self.generateSchemaFromTree()
        print(fields)
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