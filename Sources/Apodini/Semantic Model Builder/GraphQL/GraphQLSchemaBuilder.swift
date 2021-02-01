//
// Created by Sadik Ekin Ozbay on 06.01.21.
//

@_implementationOnly import Vapor
@_implementationOnly import GraphQL


func graphqlTypeMap(with type: Codable.Type) throws -> GraphQLScalarType {
    if (type == String.self) {
        return GraphQLString
    } else if (type == Int.self || type == UInt.self) {
        return GraphQLInt
    } else if (type == Float.self) {
        return GraphQLFloat
    } else if (type == Bool.self) {
        return GraphQLBoolean
    }
    throw ApodiniError(type: .serverError, reason: "graphqlTypeMap error!")
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

    private func responseTypeHandler(for responseTypeHead: Node<EnrichedInfo>) throws -> GraphQLOutputType {
        let typeValTemp = self.typeToGraphQL(type: responseTypeHead.value.typeInfo.type)

        if let typeVal = typeValTemp as? GraphQLOutputType {
            return typeVal
        }


        // Array / Optional
        if let newResponseHead = try? responseTypeHead.edited(handleArray)?.edited(handleOptional) {
            if (newResponseHead.value.cardinality == .zeroToMany(.array)) { // Array
                if let eNode = try? EnrichedInfo.node(newResponseHead.value.typeInfo.type) {
                    return try GraphQLList(responseTypeHandler(for: eNode))
                }
            } else if (newResponseHead.value.cardinality == .zeroToOne) { // Optional
                if let eNode = try? EnrichedInfo.node(newResponseHead.value.typeInfo.type) {
                    return try responseTypeHandler(for: eNode)
                }
            }
        }

        var currentFields = [String: GraphQLField]()
        for c in responseTypeHead.children {
            if let propertyInfo = c.value.propertyInfo {
                currentFields[propertyInfo.name] = GraphQLField(type: try responseTypeHandler(for: c), resolve: { source, args, context, info in
                    return try propertyInfo.get(from: source)
                })
            }
        }

        let typeName = responseTypeHead.value.typeInfo.name
        return try GraphQLObjectType(name: typeName, fields: currentFields)
    }

    private func graphQLFieldCreator(for responseTypeHead: Node<EnrichedInfo>, _ context: AnyConnectionContext<GraphQLInterfaceExporter>, _ args: [String: GraphQLArgument]) throws -> GraphQLField {
        var mutableContext = context
        let graphQLFieldType = try self.responseTypeHandler(for: responseTypeHead)
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

    func append<H: Handler>(for endpoint: Endpoint<H>, with context: AnyConnectionContext<GraphQLInterfaceExporter>) throws {
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
            let graphqlType = try  graphqlTypeMap(with: p.propertyType)
            if (p.necessity == .required) {
                self.args[leafName, default: [:]][p.name] = GraphQLArgument(type: GraphQLNonNull(graphqlType), description: p.description)
            } else {
                self.args[leafName, default: [:]][p.name] = GraphQLArgument(type: graphqlType, description: p.description)
            }

        }

        // Response type and context info
        let treeTemp = try EnrichedInfo.node(endpoint.handleReturnType)
        self.responseTypeTree[leafName] = treeTemp
        self.leafContext[leafName] = context

        // Handle Single points
        if (currentPath.count == 1) {
            self.fields[leafName] = try self.graphQLFieldCreator(for: self.responseTypeTree[leafName]!,
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

    private func graphQLRegexCheck(for str: String) -> String {
        // To handle `Names must match /^[_a-zA-Z][_a-zA-Z0-9]*$/`
        if (Array(str)[0].isNumber) {
            return "n_" + str
        } else {
            return str
        }
    }

    private func generateSchemaFromTreeHelper(_ node: String) throws -> GraphQLField {
        let nodeName = self.nameExtractor(for: node)
        if let childrenList = self.tree[node] {
            var currentFields = [String: GraphQLField]()
            if let responseType = self.responseTypeTree[nodeName], let responseContext = self.leafContext[nodeName] { // It has handler
                let fieldName = self.graphQLRegexCheck(for: responseType.value.typeInfo.name.lowercased())
                currentFields[fieldName] = try self.graphQLFieldCreator(for: responseType,
                        responseContext,
                        self.args[nodeName] ?? [:])
            }

            for child in childrenList {
                let childName = self.graphQLRegexCheck(for: self.nameExtractor(for: child))
                currentFields[childName] = try generateSchemaFromTreeHelper(child)
            }

            let checkedNodeName = self.graphQLRegexCheck(for: nodeName)
            self.types[checkedNodeName] = try GraphQLObjectType(name: checkedNodeName, fields: currentFields)
            return GraphQLField(type: self.types[checkedNodeName]!, resolve: { _, _, _, _ in "Emtpy" })
        } else {
            // Check for if we return USER type for example
            return try self.graphQLFieldCreator(for: self.responseTypeTree[node]!,
                    self.leafContext[node]!,
                    self.args[node] ?? [:])
        }
    }

    private func generateSchemaFromTree() throws {
        for (parent, _) in self.tree {
            // It is one of the roots
            if (!self.hasIncomingEdge.contains(parent)) {
                let parentName = self.nameExtractor(for: parent)
                self.fields[parentName] = try generateSchemaFromTreeHelper(parent)
            }
        }
    }

    func generate() throws -> GraphQLSchema {
        try self.generateSchemaFromTree()
        let queryType = try GraphQLObjectType(
                name: "Apodini",
                fields: self.fields
        )
        return try GraphQLSchema(
                query: queryType,
                types: Array(self.types.values)
        )
    }

}