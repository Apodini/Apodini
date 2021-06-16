//
//  PathKnowledge.swift
//  
//
//  Created by Max Obermeier on 09.05.21.
//

import Foundation


public struct PathComponents: ContextKeyKnowledgeSource {
    public typealias Key = PathComponentContextKey
    
    public let value: [PathComponent]
    
    public init(from value: [PathComponent]) {
        self.value = value
    }
}

/// The ``KnowledgeSource`` that provides access to the abolute path of an ``Endpoint`` as defined via ``Group``.
public typealias EndpointPathComponents = ScopedEndpointPathComponents<UnscopedEndpointPathComponents>

/// A ``KnowledgeSource`` that extends the base-path provided by ``EndpointPathComponents`` by appending a a path-segment for each
/// path parameter defined on the according ``Handler`` that was not explicitly used in the path.
///
/// ``Parameter`` can be modified using ``AnyPropertyOption/http(_:)`` to use ``HTTPParameterMode/path``.  In that case,
/// the endpoint's path is extended by those ``Parameter``s. ``Parameter``s which use ``HTTPParameterMode/path`` and are
/// already explicitly defined on the path via a ``Group`` are not appended, of course.
///
/// ```swift
/// struct MyHandler: Handler {
///     @Parameter(.http(.path)) var id: UUID
///
///     func handle() -> UUID { id }
/// }
///
/// struct MyWebService: WebService {
///     var content: Component {
///         MyHandler()
///     }
/// }
/// ```
///
/// In this example,  the path for `MyHandler` would be `v1/{id}`, even though the `{id}` component is not explicitly
/// specified via a ``Group``, if the exporter uses the ``EndpointPathComponentsHTTP``.
public typealias EndpointPathComponentsHTTP = ScopedEndpointPathComponents<UnscopedEndpointPathComponentsHTTP>

public struct UnscopedEndpointPathComponents: EndpointPathComponentProvider {
    public let value: [EndpointPath]
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self.value = blackboard[PathComponents.self].value
            .pathModelBuilder()
            .results.map { component in component.path }
    }
}

public protocol EndpointPathComponentProvider: KnowledgeSource {
    var value: [EndpointPath] { get }
}

public struct ScopedEndpointPathComponents<P: EndpointPathComponentProvider>: KnowledgeSource {
    public let value: [EndpointPath]
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self.value = blackboard[P.self].value
            .scoped(on: blackboard[ParameterCollection.self])
            .map { path in
                if case let .parameter(parameter) = path {
                    precondition(parameter.scopedEndpointHasDefinedParameter, "Endpoint was identified by its path while its Handler did not contain a matching Parameter for PathParameter \(path)!")
                }
                return path
            }
    }
}

public struct UnscopedEndpointPathComponentsHTTP: EndpointPathComponentProvider {
    public let value: [EndpointPath]
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        let baseElements = blackboard[UnscopedEndpointPathComponents.self].value
        let pathParametersOnHandler = blackboard[EndpointParameters.self].filter { parameter in
            parameter.parameterType == .path
        }

        let pathParametersOnHandlerButNotOnPath = pathParametersOnHandler.filter { parameter in
            !baseElements.compactMap { element in
                if case let EndpointPath.parameter(parameter) = element {
                    return parameter
                }
                return nil
            }
            .contains(where: { (parameterElement: AnyEndpointPathParameter) in
                parameterElement.id == parameter.id
            })
        }
        
        let newPathElements = pathParametersOnHandlerButNotOnPath.map { parameter in
            parameter.toInternal().derivePathParameterModel()
        }
        
        self.value = (baseElements + newPathElements)
    }
}

extension ScopedEndpointPathComponents {
    struct ParameterCollection: Apodini.ParameterCollection, KnowledgeSource {
        let parameters: [AnyEndpointParameter]
        
        init<B>(_ blackboard: B) throws where B: Blackboard {
            self.parameters = blackboard[EndpointParameters.self]
        }
        
        func findParameter(for id: UUID) -> AnyEndpointParameter? {
            parameters.first { parameter in
                parameter.id == id
            }
        }
    }
}

public extension AnyEndpoint {
    /// The ``Endpoint``'s absolute path from the root of the web service as defined by ``EndpointPathComponents``.
    var absolutePath: [EndpointPath] {
        self[EndpointPathComponents.self].value
    }
}
