//
//  File.swift
//  
//
//  Created by Eldi Cano on 28.03.21.
//

import Foundation

extension Collection where Element: ComparableObject {
    typealias Result = CollectionChangeContextNode<Element>

    func compare(to other: Self) -> Result {
        let result = Result()
        var processed: [DeltaIdentifier] = []

        for comparableObject in self {
            let currentIdentifier = comparableObject.deltaIdentifier

            if let matched = other.first(where: { $0.deltaIdentifier == currentIdentifier }) {
                result.register(comparableObject.compare(to: matched), for: currentIdentifier)
            } else {
                result.register(.removed(comparableObject), for: currentIdentifier)
            }

            processed.append(currentIdentifier)
        }

        other
            .filter { !processed.contains($0.deltaIdentifier) }
            .forEach { result.register(.added($0), for: $0.deltaIdentifier) }

        return result
    }

    func evaluate(node: ChangeContextNode) -> Change? {
        guard let result = node.collectionChangeContextNode(for: Element.self) else { return nil }

        var changes = [Change]()

        for deltaIdentifier in result.allDeltaIdentifiers {
            guard let changeForIdentifier = result.change(for: deltaIdentifier) else { continue }

            switch changeForIdentifier {
            case let comparisonResult as ComparisonResult<Element>:
                if let change = comparisonResult.change {
                    changes.append(change)
                }
            case let changeContextNode as ChangeContextNode:
                if let changedElement = first(where: { $0.deltaIdentifier == deltaIdentifier }), let change = changedElement.evaluate(result: changeContextNode) {
                    changes.append(change)
                }
            default: fatalError("Encountered an unknown result type \(type(of: changeForIdentifier))")
            }
        }

        guard !changes.isEmpty else { return nil }

        return CompositeChange(location: "[\(String(describing: Element.self))]", changes: changes)
    }
}
