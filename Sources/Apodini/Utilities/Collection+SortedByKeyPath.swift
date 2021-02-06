//
//  Created by Nityananda on 03.12.20.
//

// swiftlint:disable missing_docs

extension Collection {
    public func sorted<T>(by keyPath: KeyPath<Element, T>) -> [Element] where T: Comparable {
        sorted { lhs, rhs in
            lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
        }
    }
}
