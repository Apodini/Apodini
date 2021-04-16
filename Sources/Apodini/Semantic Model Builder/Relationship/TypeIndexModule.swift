//
//  TypeIndexModule.swift
//  
//
//  Created by Max Obermeier on 15.04.21.
//

import Foundation
import Logging

public struct TypeIndexModule<A: TruthAnchor>: DependencyBased {
    
    public static var dependencies: [ContentModule.Type] {
        [Logger.self, HandleReturnType.self, Context.self, EndpointPathModule.self, ReferenceModule.self, Operation.self, ApplicationId.self]
    }
    
    var builder: TypeIndexBuilder {
        get {
            TypeIndexBuilderStore.elements[id]!
        }
        set {
            TypeIndexBuilderStore.elements[id] = newValue
        }
    }
    
    static func builder(for app: Application) -> TypeIndexBuilder? {
        TypeIndexBuilderStore.elements[Identifier(ids: [ObjectIdentifier(app), ObjectIdentifier(Self.self)])]
    }
    
    private func createBuilderIfNotPresent(with logger: Logger) {
        if TypeIndexBuilderStore.elements[id] == nil {
            TypeIndexBuilderStore.elements[id] = TypeIndexBuilder(logger: logger)
        }
    }
    
    private let id: Identifier
    
    public init(from store: ModuleStore) throws {
        self.id = Identifier(ids: [store[ApplicationId.self].id, ObjectIdentifier(Self.self)])
        
        self.createBuilderIfNotPresent(with: store[Logger.self])
        
        let content = store[HandleReturnType.self].type
        let reference = store[ReferenceModule.self].reference
        let markedDefault = store[Context.self].get(valueFor: DefaultRelationshipContextKey.self) != nil
        let pathParameters = store[EndpointPathModule.self].absolutePath.listPathParameters()
        let operation = store[Operation.self]
        
        self.builder.indexContentType(content: content, reference: reference, markedDefault: markedDefault, pathParameters: pathParameters, operation: operation)
    }
}


private class TypeIndexBuilderStore {
    static var elements: [Identifier: TypeIndexBuilder] = [:]
}


extension Logger: ApplicationBased {
    public init(from application: Application) throws {
        self = application.logger
    }
}

private struct ApplicationId: ApplicationBased {
    let id: ObjectIdentifier
    
    init(from application: Application) throws {
        self.id = ObjectIdentifier(application)
    }
}

private struct Identifier: Hashable {
    let ids: [ObjectIdentifier]
}
