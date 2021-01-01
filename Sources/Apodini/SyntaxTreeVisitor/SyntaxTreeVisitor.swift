//
//  SyntaxTreeVisitor.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


/// The scope of a value assocated with a `ContextKey`
enum Scope {
    /// The value is only applied to the next `Handler` and discarded afterwards
    case nextHandler
    /// The value is applied to all following `Handler`s located in the substree of the current `Component` in the  synatx tree of the Apodini DSL
    case environment
}


/// The `SyntaxTreeVisitable` makes a type discoverable by a `SyntaxTreeVisitor`.
///
/// Each `Component` that needs to provide a custom `accept` implementation **must** conform to `SyntaxTreeVisitable` and **must** provide a custom `accept` implementation.
protocol SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor)
}


/// The `SyntaxTreeVisitor` is used to parse the Apodini DSL and forward the parsed result to the `SemanticModelBuilder`s.
class SyntaxTreeVisitor {
    /// The `semanticModelBuilders` that can interpret the Apodini DSL syntax tree collected by the `SyntaxTreeVisitor`
    private let semanticModelBuilders: [SemanticModelBuilder]
    /// Contains the current `ContextNode` that is used when creating a context for each registerd `Handler`
    private(set) var currentNode = ContextNode()
    /// The `currentNodeIndexPath` is  used to uniquely identify `Handlers`, even across multiple runs of an Apodini web service if the DSL has not changed.
    /// We increase the component level specific `currentNodeIndexPath` by one for each `Handler` visited in the same component level to uniquely identify `Handlers` by  the index paths.
    private var currentNodeIndexPath: [Int] = []
    
    
    /// Create a new `SyntaxTreeVisitor` that forwards the collected context and registered `Handlers` to the passed in `semanticModelBuilders`.
    /// - Parameter semanticModelBuilders: The `semanticModelBuilders` that can interpret the Apodini DSL syntax tree collected by the `SyntaxTreeVisitor`
    init(semanticModelBuilders: [SemanticModelBuilder] = []) {
        self.semanticModelBuilders = semanticModelBuilders
    }
    
    
    /// `{enter|exit}Collection` is used to keep track of the current depth into the web service data structure
    /// All visits to a component's content **must** be surrounded by a pair of `{enter|exit}Collection` calls.
    ///
    /// **Depth** is not definied in terms of path components or the exported interface, but simply how many levels of `.content` the `SyntaxTreeVisitor` is while parsing the Apodini DSL
    func enterContent() {
        currentNodeIndexPath.append(0)
    }
    
    /// `{enter|exit}Collection` is used to keep track of the current depth into the web service data structure
    /// All visits to a component's content **must** be surrounded by a pair of `{enter|exit}Collection` calls.
    ///
    /// **Depth** is not definied in terms of path components or the exported interface, but simply how many levels of `.content` the `SyntaxTreeVisitor` is while parsing the Apodini DSL
    func exitContent() {
        precondition(currentNodeIndexPath.count >= 1, "Unbalanced calls to {enter|exit}Content. Cannot exit more content levels than were entered.")
        currentNodeIndexPath.removeLast()
    }
    
    /// `(enter|exit)collectionContext` is used by the `SyntaxTreeVisitor` to keep track of the context of a `Component`.
    /// A `Component` that can contain one or more components **must** call `(enter|exit)collectionContext`  for each component to create a new context for the modifiers applied to
    /// each `Component` to avoid that one modifier applied to a `Component` is also applied to all subsequent `Component`s.
    ///
    /// Please note that `TupleComponent` automatically calls `(enter|exit)collectionContext` for each of its `Component`s stored in the tuple.
    func enterComponentContext() {
        currentNodeIndexPath[currentNodeIndexPath.endIndex - 1] += 1
        currentNode = currentNode.newContextNode()
    }
    
    /// `(enter|exit)collectionContext` is used by the `SyntaxTreeVisitor` to keep track of the context of a `Component`.
    /// A `Component` that can contain one or more components **must** call `(enter|exit)collectionContext`  for each component to create a new context for the modifiers applied to
    /// each `Component` to avoid that one modifier applied to a `Component` is also applied to all subsequent `Component`s.
    ///
    /// Please note that `TupleComponent` automatically calls `(enter|exit)collectionContext` for each of its `Component`s stored in the tuple.
    func exitComponentContext() {
        if let parentNode = currentNode.parentContextNode {
            currentNode = parentNode
        } else {
            fatalError("Tried exiting a ContextNode which didn't have any parent nodes")
        }
    }
    
    /// Adds a new context value to the current context of the `SyntaxTreeVisitor`.
    ///
    /// Call this function every time you need to register a new context value for a `ContextKey` that need to be available for all subsequent `Handlers` registered in the current `Component` subtree of the Apodini DSL.
    /// - Parameters:
    ///   - contextKey: The key of the context value
    ///   - value: The value that is assocated to the `ContextKey`
    ///   - scope: The scope of the context value as defined by the `Scope` enum
    func addContext<C: ContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        currentNode.addContext(contextKey, value: value, scope: scope)
    }
    
    
    /// Called every time a new `Handler` is registered
    /// - Parameter handler: The `Handler` that is registered
    func visit<H: Handler>(handler: H) {
        // We increase the component level specific `currentNodeIndexPath` by one for each `Handler` visited in the same component level to uniquely identify `Handlers`
        // across multiple runs of an Apodini web service.
        addContext(HandlerIndexPath.ContextKey.self, value: formHandlerIndexPathForCurrentNode(), scope: .nextHandler)
        
        // We capture the currentContextNode and make a copy that will be used when executing the request as
        // directly capturing the currentNode would be influenced by the `resetContextNode()` call and using the
        // currentNode would always result in the last currentNode that was used when visiting the component tree.
        let context = Context(contextNode: currentNode.copy())
        
        for semanticModelBuilder in semanticModelBuilders {
            semanticModelBuilder.register(handler: handler, withContext: context)
        }
        
        currentNode.resetContextNode()
    }
    
    /// **Must** be called after finishing the parsinig of the Apodini DSL to trigger the `finishedRegistration` of all `semanticModelBuilders`.
    func finishParsing() {
        for builder in semanticModelBuilders {
            builder.finishedRegistration()
        }
    }
    
    private func formHandlerIndexPathForCurrentNode() -> HandlerIndexPath {
        let rawValue = currentNodeIndexPath
            .map { String($0 - 1) } // We remove one from the current indexPath to have 0 as the first index
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
