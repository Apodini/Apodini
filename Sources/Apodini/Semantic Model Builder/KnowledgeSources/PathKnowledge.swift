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

public typealias EndpointPathComponents = ScopedEndpointPathComponents<UnscopedEndpointPathComponents>

public typealias EndpointPathComponentsWithHTTPParameterOptions = ScopedEndpointPathComponents<UnscopedEndpointPathComponentsWithHTTPParameterOptions>

public struct UnscopedEndpointPathComponents: EndpointPathComponentProvider {
    public let value: [EndpointPath]
    
    public init<B>(_ blackboard: B) throws where B : Blackboard {
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
    
    public init<B>(_ blackboard: B) throws where B : Blackboard {
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

public struct UnscopedEndpointPathComponentsWithHTTPParameterOptions: EndpointPathComponentProvider {
    
    public let value: [EndpointPath]
    
    public init<B>(_ blackboard: B) throws where B : Blackboard {
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
            }.contains(where: { (parameterElement: AnyEndpointPathParameter) in
                parameterElement.id == parameter.id
            })
        }
        
        let newPathElements = pathParametersOnHandlerButNotOnPath.map { parameter in
            parameter.derivePathParameterModel()
        }
        
        self.value = (baseElements + newPathElements)
    }
}

extension ScopedEndpointPathComponents {
    struct ParameterCollection: Apodini.ParameterCollection, KnowledgeSource {
        let parameters: [AnyEndpointParameter]
        
        init<B>(_ blackboard: B) throws where B : Blackboard {
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
    var absolutePath: [EndpointPath] {
        self[EndpointPathComponents.self].value
    }
}
