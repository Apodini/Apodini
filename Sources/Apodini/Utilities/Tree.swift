//
//  Created by Nityananda on 26.11.20.
//

// MARK: - Tree

// swiftlint:disable:next syntactic_sugar
typealias Tree<T> = Optional<Node<T>>

extension Tree {
    var isEmpty: Bool {
        self == nil
    }
}

// MARK: - Node

struct Node<T> {
    let value: T
    let children: [Node<T>]
}

extension Node {
    init(root: T, _ getChildren: (T) throws -> [T]) rethrows {
        let children = try getChildren(root)
            .map {
                try Node(root: $0, getChildren)
            }

        self.init(value: root, children: children)
    }
}

extension Node {
    func map<U>(
        _ transform: (T) throws -> U
    ) rethrows -> Node<U> {
        let value = try transform(self.value)
        let children = try self.children.compactMap { child in
            try child.map(transform)
        }

        return Node<U>(value: value, children: children)
    }

    func compactMap<U>(
        _ transform: (T) throws -> U?
    ) rethrows -> Tree<U> {
        guard let value = try transform(self.value) else {
            return nil
        }

        let children = try self.children.compactMap { child in
            try child.compactMap(transform)
        }

        return Node<U>(value: value, children: children)
    }
}

extension Node {
    func filter(
        _ isIncluded: (T) throws -> Bool
    ) rethrows -> Tree<T> {
        guard try isIncluded(self.value) else {
            return nil
        }

        let children = try self.children.compactMap { child in
            try child.filter(isIncluded)
        }

        return Node(value: value, children: children)
    }

    func contains(
        where predicate: (T) throws -> Bool
    ) rethrows -> Bool {
        guard try !predicate(value) else {
            return true
        }

        return try children.contains { child in
            try child.contains(where: predicate)
        }
    }
}

extension Node {
    func reduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult: ([Result], T) throws -> Result
    ) rethrows -> Result {
        let partialResults = try children.map { child in
            try child.reduce(initialResult, nextPartialResult)
        }

        return try nextPartialResult(partialResults, value)
    }

    func forEach(_ body: (T) throws -> Void) rethrows {
        _ = try map(body)
    }
}

extension Node {
    func edited(
        _ transform: (Node<T>) throws -> Tree<T>
    ) rethrows -> Tree<T> {
        guard let intermediate = try transform(self) else {
            return nil
        }

        let children = try intermediate.children.compactMap { child in
            try child.edited(transform)
        }

        return Node(value: intermediate.value, children: children)
    }
}

extension Node {
    func contextMap<U>(
        _ transform: (Node<T>) throws -> U
    ) rethrows -> Node<U> {
        let value = try transform(self)
        let children = try self.children.compactMap { child in
            try child.contextMap(transform)
        }

        return Node<U>(value: value, children: children)
    }
}

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
        
        return value.description
            .split(separator: "\n")
            + children
    }
    
    var description: String {
        lines.joined(separator: "\n")
    }
}
