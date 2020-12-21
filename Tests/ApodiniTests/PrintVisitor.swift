//
//  PrintVisitor.swift
//  
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

@testable import Apodini

class PrintVisitor: SyntaxTreeVisitor {
    private var indentationLevel: UInt = 0
    
    
    private var indentation: String {
        String(repeating: "  ", count: Int(indentationLevel))
    }
    
    
    override func enterCollectionItem() {
        super.enterCollectionItem()
        print("\(indentation){")
        indentationLevel += 1
    }
    
    override func addContext<C>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) where C: ContextKey {
        super.addContext(contextKey, value: value, scope: scope)
        print("\(indentation) + \(contextKey.self) = \(value)")
    }
    
    override func register<C>(component: C) where C: Handler {
        print("\(indentation)\(component)")
        printContext()
        
        currentNode.resetContextNode()
    }
    
    func printContext() {
        print("\(indentation) -> \(className(OperationContextKey.self)) = \(currentNode.getContextValue(for: OperationContextKey.self))")
        print("\(indentation) -> \(className(APIVersionContextKey.self)) = \(currentNode.getContextValue(for: APIVersionContextKey.self))")
        print("\(indentation) -> \(className(PathComponentContextKey.self)) = \(currentNode.getContextValue(for: PathComponentContextKey.self))")
        print("\(indentation) -> \(className(GuardContextKey.self)) = \(currentNode.getContextValue(for: GuardContextKey.self))")
        if !currentNode.getContextValue(for: ResponseContextKey.self).isEmpty {
            print("\(indentation) -> \(className(ResponseContextKey.self)) = \(currentNode.getContextValue(for: ResponseContextKey.self))")
        }
    }
    
    override func exitCollectionItem() {
        super.exitCollectionItem()
        indentationLevel = max(0, indentationLevel - 1)
        print("\(indentation)}")
    }
    
    private func className<T>(_ type: T.Type = T.self) -> String {
        String(describing: T.self).components(separatedBy: "<").first ?? ""
    }
}
