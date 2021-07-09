//
// Created by Andreas Bauer on 02.07.21.
//

import Foundation
import OrderedCollections
import ApodiniUtils

class DelegatingHandlerInitializerVisitor: HandlerVisitor {
    let semanticModelBuilder: SemanticModelBuilder?
    unowned let visitor: SyntaxTreeVisitor


    /// The index of the next element in the ContextKey value which we haven't
    /// considered yet. This is required as the `initializer` property will most certainly
    /// remove some elements from the original context key value.
    private var nextContextKeyIndex: Int = 0

    private var initializers: OrderedSet<DelegatingHandlerContextKey.Entry> = []

    /// Defines if `visit` is called for the first/main Handler
    private var firstHandler = true

    init(calling builder: SemanticModelBuilder?, with visitor: SyntaxTreeVisitor) {
        self.semanticModelBuilder = builder
        self.visitor = visitor

        self.queryInitializers()
    }

    func visit<H: Handler>(handler: H) throws {
        preconditionTypeIsStruct(H.self, messagePrefix: "Delegating Handler")

        // we only look at the Delegates for the "main" Handler (also to not get into an infinite loop)
        // The other ones instantiated via DelegatingHandlerInitializer are covered below.
        if firstHandler {
            firstHandler = false

            var metadata: [AnyHandlerMetadata] = []
            collectChildrenMetadata(from: handler, into: &metadata)

            for entry in metadata {
                entry.accept(self.visitor)
            }
        }

        handler.metadata.accept(self.visitor)

        self.queryInitializers()

        if !initializers.isEmpty {
            let entry = initializers.removeFirst()

            let nextHandler = try entry.initializer.anyinstance(for: handler)
            try nextHandler.accept(self)
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
        let contextValueCount = initializers.count

        // remove all previously parsed initializers
        initializers.removeSubrange(0..<nextContextKeyIndex)

        while let index = initializers.firstIndex(where: { $0.initializer is DelegationFilter }) {
            guard let filter = initializers.remove(at: index).initializer as? DelegationFilter else {
                fatalError("Reached inconsistent state. Someone introduced a bug somewhere!")
            }

            let scope = initializers[0..<index]

            // contains all entries which shall be removed
            let entriesToFilter = scope.filter { entryToFilter in
                !entryToFilter.initializer.evaluate(filter: filter)
            }

            initializers.subtract(entriesToFilter)
        }

        nextContextKeyIndex = contextValueCount
        self.initializers.append(contentsOf: initializers)
    }
}

// MARK: Delegate

/// This protocol represents a ``Delegate`` instance which wraps some sort of ``Handler``.
private protocol DelegateWithMetadata {
    /// Collect the metadata from the wrapped ``Handler`` as well as from all ``Handler`` based
    /// ``Delegates`` the wrapped ``Handler`` might contain.
    /// - Parameter metadata: The array of ``AnyHandlerMetadata`` the results should be collected into.
    func collectMetadata(into metadata: inout [AnyHandlerMetadata])
}

extension Delegate: DelegateWithMetadata where D: Handler {
    func collectMetadata(into metadata: inout [AnyHandlerMetadata]) {
        // note, we can't enter an infinite loop here, as the swift type system already covers
        // the case where a Delegate wraps itself at some point (as long as the struct requirement for Handlers holds).
        collectChildrenMetadata(from: delegateModel, into: &metadata)

        // outer metadata always has higher precedence than inner metadata when reducing, thus APPEND
        metadata.append(delegateModel.metadata)
    }
}

private func collectChildrenMetadata(from any: Any, into metadata: inout [AnyHandlerMetadata]) {
    // This is probably the part were its a bit weird how we set precedence for metadata reduction.
    // But we define that a property declared second has higher priority that the Delegate declared before,
    // similar how it is done in the Metadata Blocks itself.
    // Therefore just loop over the children in order and append them to the result

    let mirror = Mirror(reflecting: any)
    for (_, value) in mirror.children {
        if let delegate = value as? DelegateWithMetadata {
            delegate.collectMetadata(into: &metadata)
        }
    }
}
