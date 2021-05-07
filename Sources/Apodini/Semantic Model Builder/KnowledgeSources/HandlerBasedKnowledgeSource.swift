//
//  HandlerBasedKnowledgeSource.swift
//  
//
//  Created by Max Obermeier on 07.05.21.
//

import Foundation
@_implementationOnly import AssociatedTypeRequirementsVisitor

/// A helper protocol that provides typed access to the `Handler` stored in `AnyEndpointSource`.
public protocol HandlerBasedKnowledgeSource: KnowledgeSource {
    init<H: Handler>(from handler: H) throws
}

private protocol AnyEndpointSourceVisitor: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = AnyEndpointSourceVisitor
    associatedtype Input = Handler
    associatedtype Output
    
    func callAsFunction<T: Handler>(_ value: T) -> Output
}

extension HandlerBasedKnowledgeSource {
    public init<B>(_ blackboard: B) throws where B : Blackboard {
        let anyEndpointSource = blackboard[AnyEndpointSource.self]
        
        guard let result = Visitor(type: Self.self)(anyEndpointSource.handler) else {
            fatalError("AssociatedTypeRequirementsVisitor didn't find a 'Handler' in 'AnyEndpointSource.handler'")
        }
        
        self = (try result.get()) as! Self
    }
}

private struct Visitor: AnyEndpointSourceVisitor {
    typealias Output = Result<HandlerBasedKnowledgeSource, Error>
    
    let type: HandlerBasedKnowledgeSource.Type
    
    func callAsFunction<H>(_ value: H) -> Output where H : Handler {
        Result.init(catching: {
            try type.init(from: value)
        })
    }
}

extension Visitor {
    private struct _TestHandler: Handler {
        func handle() throws -> Int {
            0
        }
    }
    
    @inline(never)
    @_optimize(none)
    func _test() {
        _ = self(_TestHandler()) as Output
    }
}
