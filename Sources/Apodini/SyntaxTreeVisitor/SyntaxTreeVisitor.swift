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


protocol Visitable {
    func visit(_ visitor: SyntaxTreeVisitor)
}


class SyntaxTreeVisitor {
    private var asf: String = ""
    private let semanticModelBuilders: [SemanticModelBuilder]
    private(set) var currentNode = ContextNode()
    private var currentNodeIndexPath: [Int] = []
    
    init(semanticModelBuilders: [SemanticModelBuilder] = []) {
        self.semanticModelBuilders = semanticModelBuilders
    }
    
    private func assertCallOnlyValueWhileInCollection(caller: StaticString = #function) {
        precondition(!currentNodeIndexPath.isEmpty, "Only call '\(caller)' when the visitor is currently in a collection")
    }
    
    func enterCollection() {
        currentNodeIndexPath.append(0)
    }
    
    func exitCollection() {
        assertCallOnlyValueWhileInCollection()
        currentNodeIndexPath.removeLast()
    }
    
    
    func enterCollectionItem() {
        assertCallOnlyValueWhileInCollection()
        currentNodeIndexPath[currentNodeIndexPath.endIndex - 1] += 1
        currentNode = currentNode.newContextNode()
    }
    
    func addContext<C: ContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        currentNode.addContext(contextKey, value: value, scope: scope)
    }
    
    func getContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value {
        currentNode.getContextValue(for: C.self)
    }
    
    func register<H: Handler>(handler: H) {
        addContext(
            HandlerIndexPath.ContextKey.self,
            value: HandlerIndexPath(rawValue: currentNodeIndexPath.map(String.init).joined(separator: ":")),
            scope: .nextComponent
        )
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
        assertCallOnlyValueWhileInCollection()
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
