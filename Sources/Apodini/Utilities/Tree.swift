//
//  Created by Nityananda on 26.11.20.
//

// swiftlint:disable missing_docs
// MARK: - Tree

// swiftlint:disable syntactic_sugar
/// `Tree.none` is to `Node`, what `[]` is to `Array` or `Set`.
public typealias Tree<T> = Optional<Node<T>>
// swiftlint:enable syntactic_sugar

public extension Tree {
    var isEmpty: Bool {
        self == nil
    }
}


// MARK: - Node

/// `Node` is a wrapper that enables values to be structured in a tree.
public struct Node<T> {
    public let value: T
    public let children: [Node<T>]

    public init(value: T, children: [Node<T>]) {
        self.value = value
        self.children = children
    }
}

extension Node {
    /// Initializes an instance of `Node`.
    ///
    /// Initialize a `Node` tree from a data structure that already resembles a tree.
    /// - Parameters:
    ///   - root: The value of the root node.
    ///   - getChildren: Get node values for a parent's children, recursively.
    /// - Throws: Rethrows any error of `getChildren`
    public init(root: T, _ getChildren: (T) throws -> [T]) rethrows {
        let children = try getChildren(root).map {
            try Node(root: $0, getChildren)
        }

        self.init(value: root, children: children)
    }
}

// MARK: - Node higher-order functions

extension Node {
    /// Returns a node containing the results of mapping the given closure over the node’s values.
    /// - Parameter transform: A mapping closure. `transform` accepts a value of this node as its
    /// parameter and returns a transformed value of the same or of a different type.
    /// - Returns: A node containing the transformed values of this node.
    public func map<U>(_ transform: (T) throws -> U) rethrows -> Node<U> {
        let value = try transform(self.value)
        let children = try self.children.compactMap { child in
            try child.map(transform)
        }

        return Node<U>(value: value, children: children)
    }

    /// Returns a node containing the non-nil results of calling the given transformation with each
    /// value of this node.
    ///
    /// The child of a node, that is nil, is also not contained.
    /// - Parameter transform: A closure that accepts a value of this node as its argument and
    /// returns an optional value.
    /// - Returns: A node of the non-nil results of calling transform with each value of the node.
    public func compactMap<U>(_ transform: (T) throws -> U?) rethrows -> Tree<U> {
        guard let value = try transform(self.value) else {
            return nil
        }

        let children = try self.children.compactMap { child in
            try child.compactMap(transform)
        }

        return Node<U>(value: value, children: children)
    }
    
    /// Returns a node containing the values that pass the predicate `isIncluded`.
    ///
    /// The child of a node, that is not included in the result, is also not included.
    /// - Parameter isIncluded: A closure that takes a value of the node as its argument and returns
    /// a Boolean value that indicates wether the passed value is included.
    /// - Returns: A tree of values that
    public func filter(_ isIncluded: (T) throws -> Bool) rethrows -> Tree<T> {
        guard try isIncluded(self.value) else {
            return nil
        }

        let children = try self.children.compactMap { child in
            try child.filter(isIncluded)
        }

        return Node(value: value, children: children)
    }

    /// Returns a Boolean value indicating whether the node contains a value that satisfies the
    /// given predicate.
    /// - Parameter predicate: A closure that takes a value of the node as its argument and returns
    /// a Boolean value that indicates whether the passed value represents a match.
    /// - Returns: `true` if the node contains a value that satisfies `predicate`; otherwise,
    /// `false`.
    public func contains(where predicate: (T) throws -> Bool) rethrows -> Bool {
        if try predicate(value) {
            return true
        }

        return try children.contains { child in
            try child.contains(where: predicate)
        }
    }
    
    /// Returns the result of combining the values of the node using the given closure.
    /// - Parameters:
    ///   - nextPartialResult: A closure that combines the node's children values and the value of
    ///   the node into a new accumulating value, to be used in the next call of the
    ///   `nextPartialResult` closure or returned to the caller.
    /// - Returns: The final accumulated value.
    public func reduce<Result>(_ nextPartialResult: ([Result], T) throws -> Result) rethrows -> Result {
        let partialResults = try children.map { child in
            try child.reduce(nextPartialResult)
        }

        return try nextPartialResult(partialResults, value)
    }

    /// Calls the given closure on each value in the node.
    /// - Parameter body: A closure that takes a value of the node as a parameter.
    public func forEach(_ body: (T) throws -> Void) rethrows {
        _ = try map(body)
    }
}

public extension Node {
    /// Returns a tree edited by `transform`. Allows to modify the node freely with the information
    /// of a node and its children, but not the parent.
    ///
    /// Editing is performed from the root to the leafs. If a child is removed in the step of its
    /// parent, `transform` is no longer called with the child.
    /// - Parameter transform: A closure that accepts a node as its argument and returns a tree. A
    /// return value of `Tree.none` or `nil` is pruned from the tree.
    /// - Returns: A tree of the non-nil results of calling `transform` with each value of the node.
    func edited(_ transform: (Node<T>) throws -> Tree<T>) rethrows -> Tree<T> {
        guard let intermediate = try transform(self) else {
            return nil
        }

        let children = try intermediate.children.compactMap { child in
            try child.edited(transform)
        }

        return Node(value: intermediate.value, children: children)
    }
    
    /// Returns a node containing the results of mapping the given closure over the node.
    ///
    /// The exact arrangement of the node and its children is preserved.
    /// - Parameter transform: A mapping closure. `transform` accepts the node with all of its
    /// children as its parameter and returns a transformed value of the same or of a different type.
    /// - Returns: A node containing the transformed values of this node.
    func contextMap<U>(_ transform: (Node<T>) throws -> U) rethrows -> Node<U> {
        let value = try transform(self)
        let children = try self.children.map { child in
            try child.contextMap(transform)
        }

        return Node<U>(value: value, children: children)
    }

    /// Collect every value in the node.
    /// - Returns: A set of all values in the node.
    func collectValues() -> Set<T> where T: Hashable {
        reduce { partialResults, next in
            var set: Set = [next]
            for result in partialResults {
                set.formUnion(result)
            }
            return set
        }
    }

    /// Collect every element of an array that is a value in the node.
    /// - Returns: A set of all elements in the node that contains an array.
    func collectValues<U>() -> Set<U> where T == [U], U: Hashable {
        reduce { partialResults, next in
            var set = Set(next)
            for result in partialResults {
                set.formUnion(result)
            }
            return set
        }
    }
}

// MARK: - Node: CustomStringConvertible

extension Node: CustomStringConvertible where T: CustomStringConvertible {
    private var lines: [Substring] {
        let children = self.children
            .map { child in
                child.lines
                    .enumerated()
                    .map { index, substring -> Substring in
                        let prefix: Substring = index == 0 ? "→ " : "  "
                        return prefix + substring
                    }
            }
            .flatMap { $0 }
        
        return value.description.split(separator: "\n") + children
    }
    
    public var description: String {
        lines.joined(separator: "\n")
    }
}
