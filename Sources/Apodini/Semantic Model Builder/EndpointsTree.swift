//
// Created by Andi on 22.11.20.
//
// swiftlint:disable todo

import Vapor
import Runtime

/// This struct is used to model the RootPath for the root of the endpoints tree
/// TODO can we do better?
struct RootPath: _PathComponent {
    var description: String {
        ""
    }

    func append<P>(to pathBuilder: inout P) where P: PathBuilder {
        fatalError("RootPath instances should not be appended to anything")
    }
}



/// This struct reduces the inner structure of `@Parameter` and `@PathParameter` to a minimum for performing inference.
struct EndpointParameter {
    let id: UUID
    let name: String?
    let label: String
    let contentType: Any.Type
    let options: PropertyOptionSet<ParameterOptionNameSpace>
    let type: EndpointParameterType
    
    /// `@Parameter` categorization needed for certain interface exporters (e.g., HTTP-based).
    enum EndpointParameterType {
        case lightweight
        case content
        case path
    }
}

/// Models a single Endpoint which is identified by its PathComponents and its operation
struct Endpoint {
    /// This is a reference to the node where the endpoint is located
    // swiftlint:disable:next implicitly_unwrapped_optional
    var treeNode: EndpointsTreeNode!

    /// Description of the associated component, currently included for debug purposes
    let description: String

    /// The reference to the Context instance should be removed in the "final" state of the semantic model.
    /// I chose to include it for now as it makes the process of moving to a central semantic model easier,
    /// as implementing exporters can for now extract their needed information from the context on their own
    /// and can then pull in their requirements into the Semantic Model.
    let context: Context

    let operation: Operation

    let guards: [LazyGuard] // TODO handle RequestInjectables for every Guard instance
    let requestInjectables: [String: RequestInjectable] // TODO request injectables currently heavily rely on Vapor Requests
    let handleMethod: () -> ResponseEncodable // TODO use ResponseEncodable replacement, whatever that will be
    let responseTransformers: [() -> (AnyResponseTransformer)] // TODO handle RequestInjectables for every Transformer instance
    
    /// Type returned by `handle()`
    let handleReturnType: ResponseEncodable.Type
    
    /// Response type ultimately returned by `handle()` and possible following `ResponseTransformer`s
    lazy var responseType: ResponseEncodable.Type = {
        guard let lastResponseTransformer = self.responseTransformers.last else {
            return self.handleReturnType
        }
        return lastResponseTransformer().transformedResponseType
    }()
    
    /// All `@Parameter` `RequestInjectable`s that are used inside handling `Component`
    lazy var parameters: [EndpointParameter] = {
        requestInjectables
            .compactMap {
                let info: TypeInfo = try! typeInfo(of: type(of: $0.value))
                // TODO: is there a better way to do this instead of string comparison?
                if info.mangledName == "Parameter" {
                    let mirror = Mirror(reflecting: $0.value)
                    let id = mirror.children.first { $0.label == "id" }!.value as! UUID
                    let name = mirror.children.first { $0.label == "name" }?.value as? String
                    let label = $0.key
                    let contentType = info.genericTypes[0]
                    let options = mirror.children.first { $0.label == "options" }!.value as! PropertyOptionSet<ParameterOptionNameSpace>
                    
                    let type: EndpointParameter.EndpointParameterType = {
                        var result: EndpointParameter.EndpointParameterType = .lightweight
                        let isLosslessStringConvertible = contentType is LosslessStringConvertible.Type
                        let option = options.option(for: PropertyOptionKey.http)
                        switch option {
                        case .path:
                            precondition(isLosslessStringConvertible, "Invalid explicit option .path for parameter \(name ?? label). Option is only available for wrapped properties conforming to \(LosslessStringConvertible.self).")
                            result = .path
                        case .query:
                            precondition(isLosslessStringConvertible, "Invalid explicit option .query for parameter \(name ?? label). Option is only available for wrapped properties conforming to \(LosslessStringConvertible.self).")
                            result = .lightweight
                        case .body:
                            result = .content
                        default:
                            if !isLosslessStringConvertible {
                                result = .content
                            }
                        }
                        return result
                    }()
                    
                    return EndpointParameter(
                        id: id,
                        name: name,
                        label: label,
                        contentType: contentType,
                        options: options,
                        type: type)
                }
                return nil
            }
    }()

    lazy var pathComponents: [_PathComponent] = {
        treeNode.pathComponents
    }()
}

class EndpointsTreeNode {
    let path: _PathComponent
    lazy var pathComponents: [_PathComponent] = {
        var paths: [_PathComponent] = []
        collectPathComponents(pathComponents: &paths)
        return paths
    }()

    var endpoints: [Operation: Endpoint] = [:]

    let parent: EndpointsTreeNode?
    private var nodeChildren: [String: EndpointsTreeNode] = [:]
    var children: Dictionary<String, EndpointsTreeNode>.Values {
        nodeChildren.values
    }

    init(path: _PathComponent, parent: EndpointsTreeNode? = nil) {
        self.path = path
        self.parent = parent
    }

    func addEndpoint(_ endpoint: inout Endpoint, at paths: [PathComponent]) {
        if paths.isEmpty {
            // swiftlint:disable:next force_unwrapping
            precondition(endpoints[endpoint.operation] == nil, "Tried overwriting endpoint \(endpoints[endpoint.operation]!.description) with \(endpoint.description) for operation \(endpoint.operation)")
            precondition(endpoint.treeNode == nil, "The endpoint \(endpoint.description) is already inserted at some different place")

            endpoint.treeNode = self
            endpoints[endpoint.operation] = endpoint
        } else {
            var pathComponents = paths
            if let first = pathComponents.removeFirst() as? _PathComponent {
                var child = nodeChildren[first.description]
                if child == nil {
                    child = EndpointsTreeNode(path: first, parent: self)
                    nodeChildren[first.description] = child
                }

                // swiftlint:disable:next force_unwrapping
                child!.addEndpoint(&endpoint, at: pathComponents)
            } else {
                fatalError("Encountered PathComponent which isn't a _PathComponent!")
            }
        }
    }

    private func collectPathComponents(pathComponents: inout [_PathComponent]) {
        if path is RootPath {
            return
        }

        pathComponents.insert(path, at: 0)
        parent?.collectPathComponents(pathComponents: &pathComponents)
    }

    /// This method prints the tree structure to stdout. Added for debugging purposes.
    func printTree(indent: Int = 0) {
        let indentString = String(repeating: "  ", count: indent)

        print(indentString + path.description + "/ {")

        for (operation, endpoint) in endpoints {
            print(indentString + "  -\(operation): " + endpoint.description)
        }

        for child in nodeChildren {
            child.value.printTree(indent: indent + 1)
        }

        print(indentString + "}")
    }
}
