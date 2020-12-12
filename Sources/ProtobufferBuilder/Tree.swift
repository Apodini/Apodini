//
//  File.swift
//  
//
//  Created by Nityananda on 26.11.20.
//

// MARK: - Node

internal struct Node<T> {
    let value: T
    let children: [Node<T>]
}

extension Node {
    init(_ root: T, _ getChildren: (T) throws -> [T]) rethrows {
        let children = try getChildren(root)
            .map { try Node($0, getChildren) }
        
        self.init(value: root, children: children)
    }
}

// MARK: - Tree

// swiftlint:disable:next syntactic_sugar
typealias Tree<T> = Optional<Node<T>>

extension Tree {
    var isEmpty: Bool {
        self == nil
    }
}

extension Tree {
    func filter<T>(
        _ isIncluded: (T) throws -> Bool
    ) rethrows -> Self where Wrapped == Node<T> {
        guard let node = self,
              try isIncluded(node.value) else { return nil }
        
        let children = try node.children.filter {
            try isIncluded($0.value)
        }
        
        return Node(value: node.value, children: children)
    }
    
    func map<T, U>(
        _ transform: (T) throws -> U
    ) rethrows -> Tree<U> where Wrapped == Node<T> {
        guard let node = self else {
            return nil
        }
        
        let value = try transform(node.value)
        let children = try node.children.compactMap { (child: Tree) in
            try child.map(transform)
        }
        
        return Node(value: value, children: children)
    }
    
    func reduce<T, U>(
        into initialResult: U,
        _ updateAccumulatingResult: (inout U, T) throws -> Void
    ) rethrows -> U where Wrapped == Node<T> {
        guard let node = self else {
            return initialResult
        }
        
        var result = initialResult
        
        try updateAccumulatingResult(&result, node.value)
        
        for child in node.children as [Self] {
            result = try child.reduce(into: result, updateAccumulatingResult)
        }
        
        return result
    }
}

extension Tree {
    func edited<T>(
        _ transform: (Node<T>) throws -> Tree<T>
    ) rethrows -> Tree<T> where Wrapped == Node<T> {
        guard let node = self,
              let intermediate = try transform(node) else { return nil }
        
        let children = try intermediate.children.compactMap { (child: Tree) in
            try child.edited(transform)
        }
        
        return Node(value: intermediate.value, children: children)
    }
}

extension Tree {
    func contextMap<T, U>(
        _ transform: (Node<T>) throws -> U
    ) rethrows -> Tree<U> where Wrapped == Node<T> {
        guard let node = self else {
            return nil
        }
        
        let value = try transform(node)
        let children = try node.children.compactMap { (child: Tree) in
            try child.contextMap(transform)
        }
        
        return Node(value: value, children: children)
    }
}
