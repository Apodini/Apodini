//
// Created by Andreas Bauer on 02.07.21.
//

import Foundation
import OrderedCollections
import ApodiniUtils

class DelegatingHandlerInitializerVisitor: HandlerVisitor {
    let semanticModelBuilder: SemanticModelBuilder?
    unowned let visitor: SyntaxTreeVisitor

    /// Used as a store of what initializer we already retrieved in queryInitializers
    private var retrievedInitializers: OrderedSet<DelegatingHandlerContextKey.Entry> = []

    /// represents the working set
    private var initializers: OrderedSet<StoredContextKeyEntry> = []
    private var nextInitializerIndex = 0

    /// Defines if `visit` is called for the first/main Handler
    private var firstHandler = true

    init(calling builder: SemanticModelBuilder?, with visitor: SyntaxTreeVisitor) {
        self.semanticModelBuilder = builder
        self.visitor = visitor

        // This call to `queryInitializers` MUST be made here.
        // At this point we are sure that all modifiers have been parsed, and that all further
        // additions to the `DelegatingHandlerContextKey` stem from additions through the Metadata.
        // This allows us to easily treat those two types of source according to their ordering expectations.
        queryInitializers()
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

        print("--------")
        print("Parsing \(handler))")
        self.queryInitializers()

        if let next = nextInitializer() {
            nextInitializerIndex += 1

            let nextHandler = try next.initializer.anyinstance(for: handler)
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

        initializers.subtract(self.retrievedInitializers)
        self.retrievedInitializers.append(contentsOf: initializers)
        // `initializers` now contain only the newly added ones

        print("Adding \(initializers.count) \(initializers)")

        // apply DelegationFilters
        while let index = initializers.firstIndex(where: { $0.initializer is DelegationFilter && !$0.markedFiltered }) {
            let filterEntry = initializers[index]
            guard let filter = filterEntry.initializer as? DelegationFilter else {
                fatalError("Reached inconsistent state. Someone introduced a bug somewhere!")
            }

            filterEntry.markedFiltered = true

            if self.initializers.contains(.init(entry: filterEntry)) {
                // checks `ensureInitializerTypeUniqueness` for filters
                continue
            }

            let scope = initializers[initializers.startIndex ..< index]

            // contains all entries which shall be removed
            let entriesToFilter = scope.filter { entryToFilter in
                !entryToFilter.initializer.evaluate(filter: filter)
            }

            for entry in entriesToFilter {
                entry.markedFiltered = true
            }

            initializers.subtract(entriesToFilter)
        }


        // reverse the order of all initializers marked with the `inverseOrder` property
        var reverseOrderIndices: [Int] = []
        for index in initializers.startIndex ..< initializers.endIndex
            where initializers[index].inverseOrder {
            reverseOrderIndices.append(index)
        }

        for index in reverseOrderIndices.startIndex ..< (reverseOrderIndices.endIndex / 2) {
            let lowerIndex = reverseOrderIndices[index]
            let upperIndex = reverseOrderIndices[reverseOrderIndices.endIndex - 1 - index]

            let higher = initializers.remove(at: upperIndex)
            let lower = initializers.remove(at: lowerIndex)

            initializers.insert(higher, at: lowerIndex)
            initializers.insert(lower, at: upperIndex)
        }


        // iterate over the new initializer INORDER but prepending resulting in a REVERSE order.
        // Though, as the insertion itself happens inorder, we ensure that the `ensureInitializerTypeUniqueness` property holds.
        for value in initializers {
            self.initializers.insert(.init(entry: value), at: nextInitializerIndex)
        }
    }

    func nextInitializer() -> DelegatingHandlerContextKey.Entry? {
        while initializers[safe: nextInitializerIndex]?.entry.markedFiltered == true {
            nextInitializerIndex += 1
        }

        return initializers[safe: nextInitializerIndex]?.entry
    }
}


private struct StoredContextKeyEntry {
    let entry: DelegatingHandlerContextKey.Entry
}

extension StoredContextKeyEntry: Hashable {
    public func hash(into hasher: inout Hasher) {
        if entry.ensureInitializerTypeUniqueness {
            hasher.combine(entry.initializer.id)
            hasher.combine(entry.markedFiltered)
        } else {
            hasher.combine(entry.uuid)
        }
    }

    public static func == (lhs: StoredContextKeyEntry, rhs: StoredContextKeyEntry) -> Bool {
        lhs.entry.uuid == rhs.entry.uuid ||
            (lhs.entry.ensureInitializerTypeUniqueness == true && rhs.entry.ensureInitializerTypeUniqueness == true
                && lhs.entry.initializer.id == rhs.entry.initializer.id
                && lhs.entry.markedFiltered == rhs.entry.markedFiltered)
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
