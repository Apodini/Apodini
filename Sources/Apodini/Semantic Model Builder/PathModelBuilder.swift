//
// Created by Andreas Bauer on 05.01.21.
//

import Foundation
import ApodiniUtils

extension Array where Element == PathComponent {
    func pathModelBuilder() -> PathModelBuilder {
        var builder = PathModelBuilder()
        for component in self {
            let component = component.toInternal()
            builder.append(component)
        }
        return builder
    }
}

struct PathModelBuilder: PathComponentParser {
    var results: [StoredEndpointPath] = [.root]
    private var currentContext = ContextNode()

    fileprivate init() {}

    mutating func append(_ pathComponent: PathComponent) {
        currentContext = currentContext.newContextNode()

        let pathComponent = pathComponent.toInternal()
        pathComponent.accept(&self)

        // we don't have multiple context nodes on the same level, but just to behave as expected
        currentContext.resetContextNode()
    }

    func addContext<C: OptionalContextKey>(_ contextKey: C.Type, value: C.Value) {
        currentContext.addContext(contextKey, value: value, scope: .current)
    }

    func parseCurrentContext() -> PathContext {
        let name = currentContext.getContextValue(for: RelationshipNameContextKey.self)
        let hidden = currentContext.getContextValue(for: HideLinkContextKey.self) ?? []
        let groupEnd = currentContext.getContextValue(for: MarkGroupEndModifierContextKey.self) ?? false

        return PathContext(relationshipName: name, hiddenOperations: hidden, groupEnd: groupEnd)
    }

    mutating func visit(_ string: String) {
        results.append(StoredEndpointPath(path: .string(string), context: parseCurrentContext()))
    }

    mutating func visit<T>(_ binding: Binding<T>) {
        let identifyingType = binding.parameterOption(for: PropertyOptionKey.identifying)

        guard let parameterId = binding.parameterId else {
            fatalError("You can not pass a `Binding` as a path parameter that does not originate from a `PathParameter` or `Parameter`")
        }
        
        let pathParameter: AnyEndpointPathParameter
        if let optionalParameter = binding as? EncodeOptionalPathParameter {
            pathParameter = optionalParameter.createPathParameterWithWrappedType(id: parameterId, identifyingType: identifyingType)
        } else {
            pathParameter = EndpointPathParameter<T>(id: parameterId, identifyingType: identifyingType)
        }

        results.append(StoredEndpointPath(path: .parameter(pathParameter), context: parseCurrentContext()))
    }
}


struct StoredEndpointPath: CustomStringConvertible {
    var description: String {
        path.description
    }

    let path: EndpointPath
    let context: PathContext

    static var root: StoredEndpointPath {
        StoredEndpointPath(path: .root)
    }

    init(path: EndpointPath, context: PathContext = PathContext()) {
        self.path = path
        self.context = context
    }
}

/// Represents captured context data for a specific `EndpointPath`.
struct PathContext {
    let relationshipName: String?
    let hiddenOperations: [Operation]
    let isGroupEnd: Bool

    fileprivate init() {
        self.init(relationshipName: nil, hiddenOperations: [], groupEnd: false)
    }

    init(relationshipName: String?, hiddenOperations: [Operation], groupEnd: Bool) {
        self.relationshipName = relationshipName
        self.hiddenOperations = hiddenOperations
        self.isGroupEnd = groupEnd
    }
}

// MARK: EndpointPath Root Assertion
extension Array where Element == StoredEndpointPath {
    mutating func assertRoot() {
        if isEmpty {
            fatalError("Tried asserting stored .root path on an empty array!")
        }
        let next = removeFirst()

        if case .root = next.path {
            return
        }

        fatalError("Tried asserting stored .root but encountered \(next)")
    }
}


private protocol EncodeOptionalPathParameter {
    func createPathParameterWithWrappedType(id: UUID, identifyingType: IdentifyingType?) -> AnyEndpointPathParameter
}

// MARK: PathParameter Model
extension Binding: EncodeOptionalPathParameter where Value: OptionalProtocol, Value.Wrapped: Codable {
    func createPathParameterWithWrappedType(id: UUID, identifyingType: IdentifyingType?) -> AnyEndpointPathParameter {
        EndpointPathParameter<Value.Wrapped>(id: id, identifyingType: identifyingType)
    }
}

// MARK: PathParameter Model
extension EndpointParameter {
    func derivePathParameterModel() -> EndpointPath {
        let identifyingType = options.option(for: PropertyOptionKey.identifying)

        return .parameter(EndpointPathParameter<Type>(id: id, identifyingType: identifyingType))
    }
}
