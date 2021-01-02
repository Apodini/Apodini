//
//  SyntaxTreeVisitor.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

enum Scope {
    case nextComponent
    case environment
}


protocol SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor)
}


class SyntaxTreeVisitor {
    private var asf: String = ""
    private let semanticModelBuilders: [SemanticModelBuilder]
    private(set) var currentNode = ContextNode()
    private var currentNodeIndexPath: [Int] = [0] // the root node always forms a collection
    
    init(semanticModelBuilders: [SemanticModelBuilder] = []) {
        self.semanticModelBuilders = semanticModelBuilders
    }
    
    
    func enterCollection() {
        currentNodeIndexPath.append(0)
    }
    
    func exitCollection() {
        precondition(currentNodeIndexPath.count >= 2, "Unbalanced calls to {enter|exit}Collection. Cannot exit more collections than were entered.")
        currentNodeIndexPath.removeLast()
    }
    
    
    func enterCollectionItem() {
        currentNodeIndexPath[currentNodeIndexPath.endIndex - 1] += 1
        currentNode = currentNode.newContextNode()
    }
    
    func addContext<C: ContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        currentNode.addContext(contextKey, value: value, scope: scope)
    }
    
    func getContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value {
        currentNode.getContextValue(for: C.self)
    }
    
    func visit<H: Handler>(handler: H) {
        addContext(HandlerIndexPath.ContextKey.self, value: formHandlerIndexPathForCurrentNode(), scope: .nextComponent)
        // We capture the currentContextNode and make a copy that will be used when executing the request as
        // directly capturing the currentNode would be influenced by the `resetContextNode()` call and using the
        // currentNode would always result in the last currentNode that was used when visiting the component tree.
        let context = Context(contextNode: currentNode.copy())
        
        for semanticModelBuilder in semanticModelBuilders {
            semanticModelBuilder.register(handler: handler, withContext: context)
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
                    builder.finishedRegistration()
                }
            }
        } else {
            fatalError("Tried exiting a ContextNode which didn't have any parent nodes")
        }
    }
    
    
    private func formHandlerIndexPathForCurrentNode() -> HandlerIndexPath {
        let rawValue = currentNodeIndexPath
            .map { String(max($0, 1) - 1) }
            .joined(separator: ":")
        return HandlerIndexPath(rawValue: rawValue)
    }
}


struct HandlerIndexPath: RawRepresentable {
    let rawValue: String
    
    struct ContextKey: Apodini.ContextKey {
        static let defaultValue: HandlerIndexPath = .init(rawValue: "")
        
        static func reduce(value: inout HandlerIndexPath, nextValue: () -> HandlerIndexPath) {
            value = nextValue()
        }
    }
}
