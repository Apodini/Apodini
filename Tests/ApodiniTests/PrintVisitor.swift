//
//  PrintVisitor.swift
//  
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

@testable import Apodini
import Vapor


class PrintVisitor: Visitor {
    private var intendationLevel: UInt = 0
    
    
    private var intendation: String {
        String(repeating: "  ", count: Int(intendationLevel))
    }
    
    init() {
        super.init(Application(.testing))
    }
    
    deinit {
        app.shutdown()
    }
    
    
    override func enter<C>(collection: C) where C : ComponentCollection {
        super.enter(collection: collection)
        print("\(intendation)\(className(C.self)) {")
        intendationLevel += 1
    }
    
    override func addContext<C>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) where C : ContextKey {
        super.addContext(contextKey, value: value, scope: scope)
        print("\(intendation) + \(contextKey.self) = \(value)")
    }
    
    override func register<C>(component: C) where C: Component {
        super.register(component: component)
        
        print("\(intendation)\(component)")
        printContext()
        
        finishedRegisteringContext()
    }
    
    func printContext() {
        print("\(intendation) -> \(className(HTTPMethodContextKey.self)) = \(currentNode.getContextValue(for: HTTPMethodContextKey.self))")
        print("\(intendation) -> \(className(APIVersionContextKey.self)) = \(currentNode.getContextValue(for: APIVersionContextKey.self))")
        print("\(intendation) -> \(className(PathComponentContextKey.self)) = \(currentNode.getContextValue(for: PathComponentContextKey.self))")
        print("\(intendation) -> \(className(GuardContextKey.self)) = \(currentNode.getContextValue(for: GuardContextKey.self))")
        if currentNode.getContextValue(for: ResponseContextKey.self) != Never.self {
            print("\(intendation) -> \(className(ResponseContextKey.self)) = \(currentNode.getContextValue(for: ResponseContextKey.self))")
        }
    }
    
    override func exit<C>(collection: C) where C : ComponentCollection {
        super.exit(collection: collection)
        intendationLevel = max(0, intendationLevel - 1)
        print("\(intendation)}")
    }
    
    private func className<T>(_ type: T.Type = T.self) -> String {
        String(describing: T.self).components(separatedBy: "<").first ?? ""
    }
}
