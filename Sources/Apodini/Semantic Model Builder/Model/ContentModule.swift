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
    // TODO: how can I get rid of this???
//    init<H: Handler>(from handler: H, using context: Context, _ dependencies: [ContentModule]) throws
}

public protocol ContentModuleBased: ContentModule {
    init(from dependencies: [ContentModule]) throws
}

//extension ContentModule {
//    public init<H>(from handler: H, using context: Context, _ dependencies: [ContentModule]) throws where H : Handler {
//        if Self.self is HandlerBased {
//            self = (Self as! HandlerBased.Type).create(Self.self as! HandlerBased.Type, handler: handler)
//        }
//        throw ContentModuleError.decodingNotSupported
//    }
//
//    private static func create<M: HandlerBased, H: Handler>(_ type: M.Type, handler: H) -> M {
//        M.init(from: handler)
//    }
//}

extension ContentModuleBased {
    public init<H>(from handler: H, using context: Context, _ dependencies: [ContentModule]) throws where H : Handler {
        try self.init(from: dependencies)
    }
}

// Path information can be obtained from a `ContextBased` dependency

// TODO: break up into input/ouput types, so that traversal/reflection is hidden
public protocol HandlerBased: ContentModule {
    init<H: Handler>(from handler: H) throws
}

extension HandlerBased {
    public static var dependencies: [ContentModule.Type] { [] }
}

extension HandlerBased {
    public init<H>(from handler: H, using context: Context, _ dependencies: [ContentModule]) throws where H : Handler {
        try self.init(from: handler)
    }
}

public protocol AnyContextBased: ContentModule {
    init(from context: Context) throws
}

public protocol ContextBased: AnyContextBased {
    associatedtype Key: OptionalContextKey
    
    init(from value: Key.Value?) throws
}

extension ContextBased {
    public init(from context: Context) throws {
        try self.init(from: context.get(valueFor: Key.self))
    }
}

extension ContextBased {
    public static var dependencies: [ContentModule.Type] { [] }
}


extension ContextBased {
    public init<H>(from handler: H, using context: Context, _ dependencies: [ContentModule]) throws where H : Handler {
        try self.init(from: context.get(valueFor: Key.self))
    }
}


// MARK: ContentModuleGraph

public extension Collection where Element == ContentModule.Type {
    func satisfiableModuleSequence() throws -> [ContentModule.Type] {
        return try ContentModuleGraph(modules: Array(self)).satisfiableModuleSequence()
    }
}

private class ContentModuleGraph {
    private struct Vertex: Hashable, Codable {
        let content: ContentModule.Type
        let id: ObjectIdentifier
        
        internal init(_ content: ContentModule.Type) {
            self.id = ObjectIdentifier(content)
            self.content = content
        }
        
        init(from decoder: Decoder) throws {
            throw ContentModuleError.decodingNotSupported
        }
        
        func encode(to encoder: Encoder) throws {
            try "\(content)".encode(to: encoder)
        }
        
        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }
        
        static func == (lhs: Vertex, rhs: Vertex) -> Bool {
            lhs.content == rhs.content
        }
    }
    
    
    private let graph: UnweightedGraph<Vertex>
    
    init(modules: [ContentModule.Type]) {
        var unique = [ContentModule.Type]()
        modules.unique(in: &unique)
        
        let graph = UnweightedGraph(vertices: unique.map { content in Vertex(content) })
        
        Self.addEdges(of: modules, to: graph)
        
        self.graph = graph
    }
    
    func satisfiableModuleSequence() throws -> [ContentModule.Type] {
        let sortingResult = graph.topologicalSort()
        
        guard let sorted = sortingResult else {
            throw ContentModuleError.dependencyCycle(graph.detectCycles().map { cycle in cycle.map { vertex in vertex.content } })
        }
        
        return sorted.map { vertex in vertex.content }
    }
    
    private static func addEdges(of modules: [ContentModule.Type], to graph: UnweightedGraph<Vertex>) {
        for m in modules {
            for d in m.dependencies {
                graph.addEdge(from: Vertex(m), to: Vertex(d), directed: true)
            }
            Self.addEdges(of: m.dependencies, to: graph)
        }
    }
    
}

enum ContentModuleError: Error {
    case dependencyCycle([[ContentModule.Type]])
    case decodingNotSupported
    case dependencyNotAvailable(ContentModule.Type)
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


// MARK: AnyInterfaceExporter Conformance

extension AnyInterfaceExporter {
    var dependencies: [ContentModule.Type] {
        let visitor = ContentModuleExtractor()
        self.accept(visitor)
        return visitor.dependencies
    }
}

private class ContentModuleExtractor: InterfaceExporterVisitor {
    var dependencies: [ContentModule.Type] = []
    
    func visit<I: InterfaceExporter>(exporter: I) {
        self.dependencies = I.dependencies
    }
    
    func visit<I: StaticInterfaceExporter>(staticExporter: I) {
        self.dependencies = I.dependencies
    }
}


// MARK: Module Initialization

public class ContentModuleStore {
    private struct Identifier: Hashable {
        let content: ContentModule.Type
        let id: ObjectIdentifier
        
        internal init(_ content: ContentModule.Type) {
            self.id = ObjectIdentifier(content)
            self.content = content
        }
        
        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }
        
        static func == (lhs: Identifier, rhs: Identifier) -> Bool {
            lhs.content == rhs.content
        }
    }
    
    private let store: [Identifier: ContentModule]
    
    init<H: Handler>(_ requirements: [ContentModule.Type], for handler: H, using context: Context) throws {
        var store: [Identifier: ContentModule] = [:]
        
        for requirement in requirements {
            let dependencies = try Self.instances(for: requirement.dependencies, from: store)
            switch requirement {
            case let type as HandlerBased.Type:
                store[Identifier(requirement)] = try type.init(from: handler)
            case let type as ContentModuleBased.Type:
                store[Identifier(requirement)] = try type.init(from: dependencies)
            case let type as AnyContextBased.Type:
                store[Identifier(requirement)] = try type.init(from: context)
            default:
                fatalError("Cannot initialize unknown 'ContentModule' '\(requirement)'.")
            }
        }
        self.store = store
    }
    
    public subscript(index: ContentModule.Type) -> ContentModule? {
        get {
            store[Identifier(index)]
        }
    }
    
    private static func instances(for types: [ContentModule.Type], from store: [Identifier: ContentModule]) throws -> [ContentModule] {
        var instances = [ContentModule]()
        for type in types {
            guard let instance = store[Identifier(type)] else {
                throw ContentModuleError.dependencyNotAvailable(type)
            }
            instances.append(instance)
        }
        return instances
    }
}

// MARK: Content Providers

//protocol EndpointInformationInitializable {
//    init<H: Handler>(from handler: H, using context: Context, _ dependencies: [ContentModule]) throws
//
//    var module: ContentModule { get }
//}
//
//struct ContextProvider<Module: ContextBased>: EndpointInformationInitializable {
//    let module: ContentModule
//
//    init<H>(from handler: H, using context: Context, _ dependencies: [ContentModule]) throws where H : Handler {
//        self.module = try Module(from: context.get(valueFor: Module.Key.self))
//    }
//}
//
//extension ContextBased {
//    static var initializable: EndpointInformationInitializable.Type {
//        ContextProvider<Self>.self
//    }
//}
//
//struct HandlerProvider<Module: HandlerBased>: EndpointInformationInitializable {
//    let module: ContentModule
//
//    init<H>(from handler: H, using context: Context, _ dependencies: [ContentModule]) throws where H : Handler {
//        self.module = try Module(from: handler)
//    }
//}
//
//extension HandlerBased {
//    static var initializable: EndpointInformationInitializable.Type {
//        HandlerProvider<Self>.self
//    }
//}
//
//struct DependencyProvider<Module: ContentModuleBased>: EndpointInformationInitializable {
//    let module: ContentModule
//
//    init<H>(from handler: H, using context: Context, _ dependencies: [ContentModule]) throws where H : Handler {
//        self.module = try Module(from: dependencies)
//    }
//}
//
//extension ContentModuleBased {
//    static var initializable: EndpointInformationInitializable.Type {
//        DependencyProvider<Self>.self
//    }
//}
