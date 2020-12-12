//
//  SyntaxTreeVisitor.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor


enum Scope {
    case nextComponent
    case environment
}


protocol Visitable {
    func visit(_ visitor: SyntaxTreeVisitor)
}


class SyntaxTreeVisitor {
    private var asf: String = ""
    private let semanticModelBuilders: [SemanticModelBuilder]
    private(set) var currentNode = ContextNode()
    
    init(semanticModelBuilders: [SemanticModelBuilder] = []) {
        self.semanticModelBuilders = semanticModelBuilders
    }
    
    func enterCollectionItem() {
        currentNode = currentNode.newContextNode()
    }
    
    func addContext<C: ContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        currentNode.addContext(contextKey, value: value, scope: scope)
    }
    
    func getContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value {
        currentNode.getContextValue(for: C.self)
    }
    
    func register<C: Component>(component: C) {
        // We capture the currentContextNode and make a copy that will be used when executing the request as
        // directly capturing the currentNode would be influenced by the `resetContextNode()` call and using the
        // currentNode would always result in the last currentNode that was used when visiting the component tree.
        let context = Context(contextNode: currentNode.copy())
        
        for semanticModelBuilder in semanticModelBuilders {
            semanticModelBuilder.register(component: component, withContext: context)
        }
        
        finishedRegisteringContext()
    }
    
    private func finishedRegisteringContext() {
        currentNode.resetContextNode()
    }
    
    func exitCollectionItem() {
        if let parentNode = currentNode.parentContextNode {
            currentNode = parentNode

            if currentNode.parentContextNode == nil { // we exited to the top level node, thus we can call postProcessing
                for builder in semanticModelBuilders {
                    builder.finishedProcessing()
                }
            }
        } else {
            fatalError("Tried exiting a ContextNode which didn't have any parent nodes")
        }
    }
}
