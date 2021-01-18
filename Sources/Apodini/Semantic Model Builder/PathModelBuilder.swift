//
// Created by Andi on 05.01.21.
//

import Foundation

extension Array where Element == PathComponent {
    func buildPathModel() -> PathModelBuilder {
        var builder = PathModelBuilder()

        for component in self {
            let component = toInternalPathComponent(component)
            builder.append(component)
        }

        return builder
    }
}

struct PathRelationshipContext {
    var relationshipName: String?
    var linkHidden: Bool
}

struct PathModelBuilder: PathComponentParser {
    var results: [(EndpointPath, PathRelationshipContext)] = []
    var path: [EndpointPath] {
        var path = results.map { path, _ in
            path
        }
        path.insert(.root, at: 0)
        return path
    }
    private var currentContext = ContextNode()

    fileprivate init() {}

    mutating func append(_ pathComponent: PathComponent) {
        currentContext = currentContext.newContextNode()

        let pathComponent = toInternalPathComponent(pathComponent)
        pathComponent.accept(&self)

        // we don't have multiple context nodes on the same level, but just to behave correctly
        currentContext.resetContextNode()
    }

    func addContext<C: ContextKey>(_ contextKey: C.Type, value: C.Value) {
        currentContext.addContext(contextKey, value: value, scope: .current)
    }

    func parseCurrentContext() -> PathRelationshipContext {
        let name = currentContext.getContextValue(for: RelationshipNameContextKey.self)
        let hidden = currentContext.getContextValue(for: HideLinkContextKey.self)
        return PathRelationshipContext(
            relationshipName: name,
            linkHidden: hidden
        )
    }

    mutating func visit(_ string: String) {
        results.append(
            (.string(string), parseCurrentContext())
        )
    }

    mutating func visit<Type: Codable>(_ parameter: Parameter<Type>) {
        let pathParameter: AnyEndpointPathParameter
        if let optionalParameter = parameter as? EncodeOptionalPathParameter {
            pathParameter = optionalParameter.createPathParameterWithWrappedType(id: parameter.id)
        } else {
            pathParameter = EndpointPathParameter<Type>(id: parameter.id)
        }

        results.append(
            (.parameter(pathParameter), parseCurrentContext())
        )
    }
}

private protocol EncodeOptionalPathParameter {
    func createPathParameterWithWrappedType(id: UUID) -> AnyEndpointPathParameter
}

// MARK: PathParameter Model
extension Parameter: EncodeOptionalPathParameter where Element: ApodiniOptional, Element.Member: Codable {
    func createPathParameterWithWrappedType(id: UUID) -> AnyEndpointPathParameter {
        EndpointPathParameter<Element.Member>(id: id, nilIsValidValue: true)
    }
}

// MARK: PathParameter Model
extension EndpointParameter {
    func derivePathParameterModel() -> EndpointPath {
        .parameter(EndpointPathParameter<Type>(id: id, nilIsValidValue: nilIsValidValue))
    }
}
