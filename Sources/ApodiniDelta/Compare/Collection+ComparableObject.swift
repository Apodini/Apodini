//
//  File.swift
//  
//
//  Created by Eldi Cano on 29.03.21.
//

import Foundation

// MARK: - Collection

/// Acts as a conformance to `ComparableObject`
extension Collection where Element: ComparableObject {
    typealias Result = CollectionChangeContextNode<Element>

    func compare(to other: Self) -> Result {
        let result = Result()
        var processed: [DeltaIdentifier] = []

        forEach { comparableObject in
            let currentIdentifier = comparableObject.deltaIdentifier

            // a match is considered when the unique deltaIdentifier is found in other collection
            if let matched = other.first(where: { $0.deltaIdentifier == currentIdentifier }) {
                // here we register the result of comparing two matched objects. The result is a new ChangeContextNode
                result.register(comparableObject.compare(to: matched), for: currentIdentifier)
            } else {
                // the result of comparison is ComparisonResult<ComparableObject>
                result.register(.removed(comparableObject), for: currentIdentifier)
            }

            processed.append(currentIdentifier)
        }

        // objects in other collection that have not been processed are registered as additions
        other
            .filter { !processed.contains($0.deltaIdentifier) }
            .forEach { result.register(.added($0), for: $0.deltaIdentifier) }

        return result
    }

    /// Evaluates the changes of comparing two collections
    func evaluate(node: ChangeContextNode) -> Change? {
        // retrieves the result calculated in `compare(to:)`
        guard let result = node.change(comparable: Element.self) else {
            return nil
        }

        var changes = [Change]()

        for deltaIdentifier in result.allDeltaIdentifiers {
            guard let changeForIdentifier = result.change(for: deltaIdentifier) else { continue }

            switch changeForIdentifier {
            case let comparisonResult as ComparisonResult<Element>:
                if let change = comparisonResult.change {
                    changes.append(change)
                }
            case let changeContextNode as ChangeContextNode:
                if let changedElement = first(where: { $0.deltaIdentifier == deltaIdentifier }),
                   let change = changedElement.evaluate(result: changeContextNode, embeddedInCollection: true) {
                    changes.append(change)
                }
            default: fatalError("Encountered an unknown result type \(type(of: changeForIdentifier))")
            }
        }

        guard !changes.isEmpty else {
            return nil
        }

        return .compositeChange(location: "[\(Element.changeLocation)]", changes: changes)
    }
}
