//
// Created by Sadik Ekin Ozbay on 06.01.21.
//

@_implementationOnly import Vapor
import GraphQL


func graphqlTypeMap(with type: Codable.Type) -> GraphQLScalarType {
    if (type == String.self) {
        return GraphQLString
    } else if (type == Int.self || type == UInt.self) {
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


class GraphQLSchemaBuilder {
    private var tree = [String: Set<String>]()
    private var leafContext = [String: AnyConnectionContext<GraphQLInterfaceExporter>]()
    private var hasIncomingEdge = Set<String>()


    // GraphQL Related values
    private var types = [String: GraphQLObjectType]()
    private var fields = [String: GraphQLField]()
    private var args = [String: [String: GraphQLArgument]]()
    private var responseTypeTree = [String: Node<EnrichedInfo>]()

    private func typeToGraphQL(type: Any.Type) -> GraphQLType? {
        if (type == String.self) {
            return GraphQLString
        }
        if (type == Int.self || type == UInt.self) {
            return GraphQLInt
        }
        if (type == Bool.self) {
            return GraphQLBoolean
        }
        if (type == Float.self) {
            return GraphQLFloat
        }
        return nil
    }

    private func responseTypeHandler(for responseTypeHead: Node<EnrichedInfo>) -> GraphQLOutputType {
        let typeValTemp = self.typeToGraphQL(type: responseTypeHead.value.typeInfo.type)

        if let typeVal = typeValTemp {
            return typeVal as! GraphQLOutputType
        }


        // Array / Optional
        if let newResponseHead = try! responseTypeHead.edited(handleArray)?.edited(handleOptional) {
            if (newResponseHead.value.cardinality == .zeroToMany(.array)) { // Array
                if let eNode = try? EnrichedInfo.node(newResponseHead.value.typeInfo.type) {
                    return GraphQLList(responseTypeHandler(for: eNode))
                }
            } else if (newResponseHead.value.cardinality == .zeroToOne) { // Optional
                if let eNode = try? EnrichedInfo.node(newResponseHead.value.typeInfo.type) {
                    return responseTypeHandler(for: eNode)
                }
            }
        }

        var currentFields = [String: GraphQLField]()
        for c in responseTypeHead.children {
            if let propertyInfo = c.value.propertyInfo {
                currentFields[propertyInfo.name] = GraphQLField(type: responseTypeHandler(for: c), resolve: { source, args, context, info in
                    return try propertyInfo.get(from: source)
                })
            }
        }

        let typeName = responseTypeHead.value.typeInfo.name
        return try! GraphQLObjectType(name: typeName, fields: currentFields)
    }

    private func graphQLFieldCreator(for responseTypeHead: Node<EnrichedInfo>, _ context: AnyConnectionContext<GraphQLInterfaceExporter>, _ args: [String: GraphQLArgument]) -> GraphQLField {
        var mutableContext = context
        let graphQLFieldType = self.responseTypeHandler(for: responseTypeHead)
        return GraphQLField(type: graphQLFieldType, args: args, resolve: { gSource, gArgs, gContext, gEventLoop, gInfo in
            let request = GraphQLRequest(source: gSource, args: gArgs, context: gContext, info: gInfo)
            let vaporRequest = gContext as! Vapor.Request
            let response: EventLoopFuture<Response<AnyEncodable>> = mutableContext.handle(request: request, eventLoop: vaporRequest.eventLoop.next())

            return response.flatMapThrowing { encodableAction -> Any? in
                switch encodableAction {
                case let .send(element),
                     let .final(element):
                    return element.wrappedValue
                case .nothing, .end:
                    return ".nothing, .end"
                }
            }

        })
    }


    // Generated adjacency list tree
    func append<H: Handler>(for endpoint: Endpoint<H>, with context: AnyConnectionContext<GraphQLInterfaceExporter>) {
        // Remove parameters from the path by using `":" filter`
        var currentPath = endpoint.absolutePath.map {
            $0.description.lowercased()
        }.filter {
            $0.first != ":"
        }

        // Remove `root`
        currentPath.removeFirst()
        // Remove `v1`
        currentPath.removeFirst()

        print("The current path is ->", currentPath)

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

        // Handle arguments
        for p in endpoint.parameters {
            let graphqlType = graphqlTypeMap(with: p.propertyType)
            if (p.necessity == .required) {
                self.args[leafName, default: [:]][p.name] = GraphQLArgument(type: GraphQLNonNull(graphqlType), description: p.description)
            } else {
                self.args[leafName, default: [:]][p.name] = GraphQLArgument(type: graphqlType, description: p.description)
            }

        }

        // Response type and context info
        let treeTemp = try! EnrichedInfo.node(endpoint.handleReturnType)
        self.responseTypeTree[leafName] = treeTemp
        self.leafContext[leafName] = context

        // Handle Single points
        if (currentPath.count == 1) {
            self.fields[leafName] = self.graphQLFieldCreator(for: self.responseTypeTree[leafName]!,
                    self.leafContext[leafName]!,
                    self.args[leafName] ?? [:])
            return
        }

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

    // To handle `Names must match /^[_a-zA-Z][_a-zA-Z0-9]*$/`
    private func graphQLRegexCheck(for str: String) -> String {
        if (Array(str)[0].isNumber) {
            return "n_" + str
        } else {
            return str
        }
    }

    private func generateSchemaFromTreeHelper(_ node: String) -> GraphQLField {
        let nodeName = self.nameExtractor(for: node)
        if let childrenList = self.tree[node] {
            var currentFields = [String: GraphQLField]()
            if let responseType = self.responseTypeTree[nodeName], let responseContext = self.leafContext[nodeName] { // It has handler
                let fieldName = self.graphQLRegexCheck(for: responseType.value.typeInfo.name.lowercased())
                currentFields[fieldName] = self.graphQLFieldCreator(for: responseType,
                        responseContext,
                        self.args[nodeName] ?? [:])
            }

            for child in childrenList {
                let childName = self.graphQLRegexCheck(for: self.nameExtractor(for: child)) // child.components(separatedBy: "_").filter({ $0 != "" }).last ?? "None"
                // if let childrenList = self.tree[node] {
                currentFields[childName] = generateSchemaFromTreeHelper(child)
            }

            let checkedNodeName = self.graphQLRegexCheck(for: nodeName)
            self.types[checkedNodeName] = try! GraphQLObjectType(name: checkedNodeName, fields: currentFields)
            return GraphQLField(type: self.types[checkedNodeName]!, resolve: { _, _, _, _ in "Emtpy" })
        } else {
            // Check for if we return USER type for example
            return self.graphQLFieldCreator(for: self.responseTypeTree[node]!,
                    self.leafContext[node]!,
                    self.args[node] ?? [:])
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