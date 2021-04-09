//
//  ContentModule.swift
//  
//
//  Created by Max Obermeier on 09.04.21.
//

import Foundation
import SwiftGraph

// MARK: ContentModule

public protocol ContentModule {
    static var dependencies: [ContentModule.Type] { get }
}

extension ContentModule {
    public static var dependencies: [ContentModule.Type] { [] }
}

public protocol ContentModuleBased: ContentModule {
    associatedtype Dependency: ContentModule
    
    init(from module: Dependency) throws
}

// Path information can be obtained from a `ContextBased` dependency

// TODO: break up into input/ouput types, so that traversal/reflection is hidden
public protocol HandlerBased: ContentModule {
    init<H: Handler>(from handler: H) throws
}

public protocol ContextBased: ContentModule {
    associatedtype Key: OptionalContextKey
    
    init(from value: Key.Value) throws
}

// MARK: ContentModuleGraph

public extension Collection where Element == ContentModule.Type {
    func satisfyableModuleSequence() throws -> [ContentModule.Type] {
        return try ContentModuleGraph(modules: Array(self)).satisfyableModuleSequence()
    }
}

private class ContentModuleGraph {
    
    private let content: [UUID: ContentModule.Type]
    
    private let graph: UnweightedGraph<UUID>
    
    init(modules: [ContentModule.Type]) {
        var unique = [ContentModule.Type]()
        modules.unique(in: &unique)
        
        var content = [UUID: ContentModule.Type]()
        
        for m in unique {
            content[UUID()] = m
        }
        
        self.content = content
        
        self.graph = UnweightedGraph(vertices: content.map { (key, _) in key })
    }
    
    func satisfyableModuleSequence() throws -> [ContentModule.Type] {
        let sortingResult = graph.topologicalSort()
        
        guard let sorted = sortingResult else {
            throw ContentModuleError.dependencyCycle(graph.detectCycles().map { cycle in cycle.map { vertex in self.content[vertex]! } })
        }
        
        return sorted.map { vertex in self.content[vertex]! }
    }
    
}

enum ContentModuleError: Error {
    case dependencyCycle([[ContentModule.Type]])
}

private extension Collection where Element == ContentModule.Type {
    func unique(in buffer: inout [Element]) {
        for module in self {
            if !buffer.contains(where: { m in m == module }) {
                buffer.append(module)
                module.dependencies.unique(in: &buffer)
            }
        }
    }
}
