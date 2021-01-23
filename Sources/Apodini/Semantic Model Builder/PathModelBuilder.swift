//
// Created by Andi on 05.01.21.
//

import Foundation

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
        let groupEnd = currentContext.getContextValue(for: MarkGroupEndModifierContextKey.self) ?? false

        if let hidden = currentContext.getContextValue(for: HideLinkContextKey.self) {
            return PathContext(relationshipName: name, linkHidden: true, hiddenOperations: hidden, groupEnd: groupEnd)
        } else {
            return PathContext(relationshipName: name, groupEnd: groupEnd)
        }
    }

    mutating func visit(_ string: String) {
        results.append(StoredEndpointPath(path: .string(string), context: parseCurrentContext()))
    }

    mutating func visit<Type: Codable>(_ parameter: Parameter<Type>) {
        let identifyingType = parameter.option(for: PropertyOptionKey.identifying)

        let pathParameter: AnyEndpointPathParameter
        if let optionalParameter = parameter as? EncodeOptionalPathParameter {
            pathParameter = optionalParameter.createPathParameterWithWrappedType(id: parameter.id, identifyingType: identifyingType)
        } else {
            pathParameter = EndpointPathParameter<Type>(id: parameter.id, identifyingType: identifyingType)
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
        StoredEndpointPath(path: .root, context: PathContext())
    }
}

struct PathContext {
    var relationshipName: String?
    var linkHidden: Bool
    var hiddenOperations: [Operation]
    var isGroupEnd: Bool

    init(relationshipName: String? = nil, groupEnd: Bool = false) {
        self.init(relationshipName: relationshipName, linkHidden: false, groupEnd: groupEnd)
    }

    init(relationshipName: String?, linkHidden: Bool, hiddenOperations: [Operation] = [], groupEnd: Bool = false) {
        self.relationshipName = relationshipName
        self.linkHidden = linkHidden
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

        switch next.path {
        case .root:
            break
        default:
            fatalError("Tried asserting stored .root but encountered \(next)")
        }
    }
}


private protocol EncodeOptionalPathParameter {
    func createPathParameterWithWrappedType(id: UUID, identifyingType: IdentifyingType?) -> AnyEndpointPathParameter
}

// MARK: PathParameter Model
extension Parameter: EncodeOptionalPathParameter where Element: ApodiniOptional, Element.Member: Codable {
    func createPathParameterWithWrappedType(id: UUID, identifyingType: IdentifyingType?) -> AnyEndpointPathParameter {
        EndpointPathParameter<Element.Member>(id: id, nilIsValidValue: true, identifyingType: identifyingType)
    }
}

// MARK: PathParameter Model
extension EndpointParameter {
    func derivePathParameterModel() -> EndpointPath {
        let identifyingType = options.option(for: PropertyOptionKey.identifying)

        return .parameter(EndpointPathParameter<Type>(id: id, nilIsValidValue: nilIsValidValue, identifyingType: identifyingType))
    }
}
