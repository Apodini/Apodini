//
//  ContentModule.swift
//  
//
//  Created by Max Obermeier on 09.04.21.
//

import Foundation
import SwiftGraph

/// A `TruthAnchor` is a type that `ContentModule`s can refer to for establishing a sense of identity.
/// E.g. a `RelationshipModule<RESTInterfaceExporter>` and a
/// `RelationshipModule<GraphQLInterfaceExporter>` could collect different content. However,
/// the OpenAPI exporter would want to export the exact same information as the REST exporter. Thus,
/// the OpenAPI exporter would use `RelationshipModule<RESTInterfaceExporter>`, too.
/// For that to work both `RESTInterfaceExporter` and `GraphQLInterfaceExporter` must conform
/// to `TrustAnchor`.
/// - Note: This is not particularely helpful yet, since we always expose the **whole** service definition to all
/// exporters. However, one could envision a `.hide(from exporter: TruthAnchor.Type)` modifier on
/// `Component`s, where this feature becomes crucial.
public protocol TruthAnchor { }

// MARK: ContentModule
public protocol ContentModule {
    static var dependencies: [ContentModule.Type] { get }
}

public protocol DependencyBased: ContentModule {
    init(from store: ModuleStore) throws
}

extension DependencyBased {
    public init<H>(from handler: H, using context: Context, _ store: ModuleStore) throws where H : Handler {
        try self.init(from: store)
    }
}

// Path information can be obtained from a `ContextBased` dependency

// TODO: break up into input/ouput types, so that traversal/reflection is hidden
public protocol _HandlerBased: ContentModule {
    init<H: Handler>(from handler: H) throws
}

extension _HandlerBased {
    public static var dependencies: [ContentModule.Type] { [] }
}

extension _HandlerBased {
    public init<H>(from handler: H, using context: Context, _ dependencies: [ContentModule]) throws where H : Handler {
        try self.init(from: handler)
    }
}

public protocol AnyContextBased: ContentModule {
    init(from context: Context) throws
}

public protocol OptionalContextBased: AnyContextBased {
    associatedtype Key: OptionalContextKey
    
    init(from value: Key.Value?) throws
}

extension OptionalContextBased {
    public init(from context: Context) throws {
        try self.init(from: context.get(valueFor: Key.self))
    }
}

public protocol ContextBased: OptionalContextBased where Key: ContextKey {
    init(from value: Key.Value) throws
}

extension ContextBased {
    public init(from value: Key.Value?) throws {
        try self.init(from: value ?? Key.defaultValue)
    }
}

extension OptionalContextBased {
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


// MARK: Module Store

public protocol ModuleStore {
    subscript<M: ContentModule>(index: M.Type) -> M { get }
}

enum ContentModuleStoreEvaluationStrategy {
    /// Any mode is intended for prototyping and testing. Errors thrown by the modules
    /// are escalated to fatalErrors.
    case any
    /// Only the provided list of modules is initilaizted. Trying to initialize a different module
    /// causes a fatalError.
    case fixed([ContentModule.Type])
}

class ContentModuleStore: ModuleStore {
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
    
    private var store: [Identifier: ContentModule] = [:]
    
    private let resolve: (ContentModule.Type, ContentModuleStore) throws -> ContentModule?
    
    init<H: Handler>(_ strategy: ContentModuleStoreEvaluationStrategy = .any, for handler: H, using context: Context) throws {
        
        switch strategy {
        case .any:
            self.resolve = { type, store throws in
                let requirements = try ([type] as [ContentModule.Type]).satisfiableModuleSequence()
                try store.initialize(requirements, handler: handler, context: context)
                return store.store[Identifier(type)]
            }
        case let .fixed(modules):
            let requirements = Set(try modules.satisfiableModuleSequence().map(Identifier.init))
            self.resolve = { type, store in
                guard requirements.contains(Identifier(type)) else {
                    throw ContentModuleError.dependencyNotAvailable(type)
                }
                
                let requirements = try ([type] as [ContentModule.Type]).satisfiableModuleSequence()
                try store.initialize(requirements, handler: handler, context: context)
                return store.store[Identifier(type)]
            }
        }
    }
    
    public subscript<M: ContentModule>(index: M.Type) -> M {
        get {
            do {
                let module = try self.resolve(index, self)!
                return module as! M
            } catch {
                fatalError("ContentModuleStore could not retrieve module \(index): \(error)")
            }
        }
    }
    
    private func initialize<H: Handler>(_ requirements: [ContentModule.Type], handler: H, context: Context) throws {
        let requirements = try requirements.satisfiableModuleSequence()
        for requirement in requirements {
            if store[Identifier(requirement)] == nil {
                switch requirement {
                case let type as _HandlerBased.Type:
                    store[Identifier(requirement)] = try type.init(from: handler)
                case let type as DependencyBased.Type:
                    store[Identifier(requirement)] = try type.init(from: ModuleStoreView(store: self, viewer: type))
                case let type as AnyContextBased.Type:
                    store[Identifier(requirement)] = try type.init(from: context)
                default:
                    fatalError("Cannot initialize unknown 'ContentModule' '\(requirement)'.")
                }
            }
        }
    }
}

struct ModuleStoreView: ModuleStore {
    let store: ModuleStore
    let viewer: DependencyBased.Type
    
    public subscript<M>(index: M.Type) -> M where M : ContentModule {
        guard viewer.dependencies.contains(where: { d in d == index }) else {
            fatalError("\(viewer) tried to access dependency that is not listed in its 'dependencies' property.")
        }
        return store[index]
    }
}

public class MockModuleStore: ModuleStore {
    
    private let content: [ObjectIdentifier: ContentModule]
    
    public init(_ contents: (ContentModule.Type, ContentModule)...) {
        var c = [ObjectIdentifier: ContentModule]()
        for content in contents {
            c[ObjectIdentifier(content.0)] = content.1
        }
        self.content = c
    }
    
    public subscript<M>(index: M.Type) -> M where M : ContentModule {
        content[ObjectIdentifier(index)]! as! M
    }
    
}
