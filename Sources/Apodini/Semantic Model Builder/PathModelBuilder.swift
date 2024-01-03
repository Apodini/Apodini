//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import ApodiniUtils

extension Array where Element == any PathComponent {
    func pathModelBuilder() -> PathModelBuilder {
        var builder = PathModelBuilder()
        for component in self {
            builder.append(component)
        }
        return builder
    }
}

// MARK: Global Builder


struct PathModelBuilder: PathComponentParser {
    var results: [StoredEndpointPath] = [.root]
    private var currentContext = ContextNode()

    fileprivate init() {}

    mutating func append(_ pathComponent: any PathComponent) {
        currentContext = currentContext.newContextNode()

        let pathComponent = pathComponent.toInternal()
        pathComponent.accept(&self)
    }

    func addContext<C: OptionalContextKey>(_ contextKey: C.Type, value: C.Value) {
        currentContext.addContext(contextKey, value: value, scope: .current)
    }

    func parseCurrentContext() -> PathContext {
        let context = currentContext.export()

        let name = context.get(valueFor: RelationshipNameContextKey.self)
        let hidden = context.get(valueFor: HideLinkContextKey.self) ?? []
        let groupEnd = context.get(valueFor: MarkGroupEndModifierContextKey.self) ?? false

        return PathContext(relationshipName: name, hiddenOperations: hidden, groupEnd: groupEnd)
    }

    mutating func visit(_ string: String) {
        results.append(StoredEndpointPath(path: .string(string), context: parseCurrentContext()))
    }

    mutating func visit<Type: Codable>(_ parameter: Parameter<Type>) {
        results.append(StoredEndpointPath(path: .parameter(parameter.toPathParameter()), context: parseCurrentContext()))
    }
}

// MARK: Local Builder
private struct PathComponentElementParser: PathComponentParser {
    var element: EndpointPath?
    
    mutating func visit(_ string: String) {
        element = .string(string)
    }
    
    mutating func visit<Type: Codable>(_ parameter: Parameter<Type>) {
        element = .parameter(parameter.toPathParameter())
    }
}

// MARK: Helpers

private extension Parameter {
    func toPathParameter() -> any AnyEndpointPathParameter {
        let identifyingType = self.option(for: PropertyOptionKey.identifying)

        let pathParameter: any AnyEndpointPathParameter
        if let optionalParameter = self as? any EncodeOptionalPathParameter {
            pathParameter = optionalParameter.createPathParameterWithWrappedType(id: self.id, identifyingType: identifyingType)
        } else {
            pathParameter = EndpointPathParameter<Element>(id: self.id, identifyingType: identifyingType)
        }
        return pathParameter
    }
}

extension PathComponent {
    func toEndpointPath() -> EndpointPath {
        var parser = PathComponentElementParser()
        self.toInternal().accept(&parser)
        return parser.element!
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
    func createPathParameterWithWrappedType(id: UUID, identifyingType: IdentifyingType?) -> any AnyEndpointPathParameter
}

// MARK: PathParameter Model
extension Parameter: EncodeOptionalPathParameter where Element: OptionalProtocol, Element.Wrapped: Codable {
    func createPathParameterWithWrappedType(id: UUID, identifyingType: IdentifyingType?) -> any AnyEndpointPathParameter {
        EndpointPathParameter<Element.Wrapped>(id: id, identifyingType: identifyingType)
    }
}

// MARK: PathParameter Model
extension EndpointParameter {
    func derivePathParameterModel() -> EndpointPath {
        let identifyingType = options.option(for: PropertyOptionKey.identifying)

        return .parameter(EndpointPathParameter<Type>(id: id, identifyingType: identifyingType))
    }
}
