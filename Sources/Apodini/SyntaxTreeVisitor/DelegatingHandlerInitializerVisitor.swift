//
// Created by Andreas Bauer on 02.07.21.
//

import ApodiniUtils

class DelegatingHandlerInitializerVisitor: HandlerVisitor {
    let semanticModelBuilder: SemanticModelBuilder?
    unowned let visitor: SyntaxTreeVisitor

    var nextInitializersIndex = 0
    var initializers: [AnyDelegatingHandlerInitializer] = []

    init(calling builder: SemanticModelBuilder?, with visitor: SyntaxTreeVisitor) {
        self.semanticModelBuilder = builder
        self.visitor = visitor

        self.queryInitializers()
    }

    func visit<H: Handler>(handler: H) throws {
        preconditionTypeIsStruct(H.self, messagePrefix: "Delegating Handler")

        handler.metadata.accept(self.visitor)
        self.queryInitializers()

        if !initializers.isEmpty {
            let initializer = initializers.removeFirst()

            if let filter = initializer as? DelegationFilter {
                initializers = initializers.filter { initializerToFilter in
                    initializerToFilter.evaluate(filter: filter)
                }
                try visit(handler: handler)
            } else {
                let nextHandler = try initializer.anyinstance(for: handler)
                try nextHandler.accept(self)
            }
        } else {
            let context = visitor.currentNode.export()
            semanticModelBuilder?.register(handler: handler, withContext: context)
        }
    }

    /// This method queries the latest value for the `DelegatingHandlerContextKey` and updates
    /// the current array of captured initializers in the visitor.
    /// This is important to update the array of initializers after we have parsed the Metadata of a `Handler`.
    /// That mechanism allows for dynamically adding `DelegatingHandlerInitializer` through Metadata.
    func queryInitializers() {
        var initializers = visitor.currentNode.peekValue(for: DelegatingHandlerContextKey.self)

        // remove all previously parsed initializers
        initializers.removeSubrange(0..<nextInitializersIndex)

        let newInitializers = (
            initializers.filter { prepend, _ in prepend }.reversed()
            +
            initializers.filter { prepend, _ in !prepend }
        ).map { _, initializer in initializer }

        nextInitializersIndex += newInitializers.count

        self.initializers.append(contentsOf: newInitializers)
    }
}
