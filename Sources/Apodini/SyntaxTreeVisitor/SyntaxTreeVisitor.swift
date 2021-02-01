//
//  SyntaxTreeVisitor.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


/// The scope of a value associated with a `ContextKey`
enum Scope {
    /// The value is only applied to the current `ContextNode` and discarded afterwards
    case current
    /// The value is applied to all following `ContextNodes`s located in the subtree of the current `ContextNode`
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
    private let modelBuilder: SemanticModelBuilder?
    /// Contains the current `ContextNode` that is used when creating a context for each registered `Handler`
    private(set) var currentNode = ContextNode()
    /// The `currentNodeIndexPath` is  used to uniquely identify `Handlers`, even across multiple runs of an Apodini web service if the DSL has not changed.
    /// We increase the component level specific `currentNodeIndexPath` by one for each `Handler` visited in the same component level to uniquely identify `Handlers` by  the index paths.
    private var currentNodeIndexPath: [Int] = []
    
    
    /// Create a new `SyntaxTreeVisitor` that forwards the collected context and registered `Handlers` to the passed in `semanticModelBuilders`.
    /// - Parameter modelBuilder: The `SemanticModelBuilder` that can interpret the Apodini DSL syntax tree collected by the `SyntaxTreeVisitor`
    init(modelBuilder: SemanticModelBuilder? = nil) {
        self.modelBuilder = modelBuilder
    }
    
    
    /// `enterCollection` is used to keep track of the current depth into the web service data structure
    /// All visits (`accept` call) to a component's content **must** be executed within the closure passed to `enterContent`.
    ///
    /// **Depth** is not defined in terms of path components or the exported interface, but simply how many levels of `.content` the `SyntaxTreeVisitor` is while parsing the Apodini DSL
    func enterContent(_ block: () throws -> Void) rethrows {
        currentNodeIndexPath.append(0)
        
        try block()
        
        precondition(currentNodeIndexPath.count >= 1, "Unbalanced calls to {enter|exit}Content. Cannot exit more content levels than were entered.")
        currentNodeIndexPath.removeLast()
    }
    
    /// `enterComponentContext` is used by the `SyntaxTreeVisitor` to keep track of the context of a `Component`.
    /// A `Component` that can contain one or more components **must** call accept of the `Component`s or register `Handler`s within the closure passed to `enterComponentContext` to create a new context
    /// for the modifiers applied to each `Component` to avoid that one modifier applied to a `Component` is also applied to all subsequent `Component`s.
    ///
    /// Please note that `TupleComponent` automatically calls `enterComponentContext` for each of its `Component`s stored in the tuple.
    func enterComponentContext(_ block: () throws -> Void) rethrows {
        currentNodeIndexPath[currentNodeIndexPath.endIndex - 1] += 1
        currentNode = currentNode.newContextNode()
        
        try block()
        
        if let parentNode = currentNode.parentContextNode {
            currentNode = parentNode
        } else {
            fatalError("Tried exiting a ContextNode which didn't have any parent nodes")
        }
    }
    
    /// Adds a new context value to the current context of the `SyntaxTreeVisitor`.
    ///
    /// Call this function every time you need to register a new context value for a `ContextKey` that need to be available
    /// for all subsequent `Handlers` registered in the current `Component` subtree of the Apodini DSL.
    /// - Parameters:
    ///   - contextKey: The key of the context value
    ///   - value: The value that is associated to the `ContextKey`
    ///   - scope: The scope of the context value as defined by the `Scope` enum
    func addContext<C: OptionalContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        currentNode.addContext(contextKey, value: value, scope: scope)
    }
    
    
    /// Called every time a new `Handler` is registered
    /// - Parameter handler: The `Handler` that is registered
    func visit<H: Handler>(handler: H) {
        // We increase the component level specific `currentNodeIndexPath` by one for each `Handler` visited in the same component level to uniquely identify `Handlers`
        // across multiple runs of an Apodini web service.
        addContext(HandlerIndexPath.ContextKey.self, value: formHandlerIndexPathForCurrentNode(), scope: .current)
        
        // We capture the currentContextNode and make a copy that will be used when executing the request as
        // directly capturing the currentNode would be influenced by the `resetContextNode()` call and using the
        // currentNode would always result in the last currentNode that was used when visiting the component tree.
        let context = Context(contextNode: currentNode.copy())

        modelBuilder?.register(handler: handler, withContext: context)
        
        currentNode.resetContextNode()
    }
    
    /// **Must** be called after finishing the parsing of the Apodini DSL to trigger the `finishedRegistration` of all `semanticModelBuilders`.
    func finishParsing() {
        modelBuilder?.finishedRegistration()
    }
    
    private func formHandlerIndexPathForCurrentNode() -> HandlerIndexPath {
        let rawValue = currentNodeIndexPath
            .map { String($0 - 1) } // We remove one from the current indexPath to have 0 as the first index
            .joined(separator: ".")
        return HandlerIndexPath(rawValue: rawValue)
    }
}


struct HandlerIndexPath: RawRepresentable {
    let rawValue: String
    
    struct ContextKey: Apodini.ContextKey {
        typealias Value = HandlerIndexPath
        static let defaultValue: HandlerIndexPath = .init(rawValue: "")
    }
}
