//
//  AsyncSubscribingSequence.swift
//  
//
//  Created by Max Obermeier on 11.07.21.
//

import Foundation
import _Concurrency

public protocol CompletionCandidate {
    var isCompletion: Bool { get }
}

public protocol Subscribable {
    associatedtype Event: CompletionCandidate
    associatedtype Handle
    
    func register(_ callback: @escaping (Event) -> Void) -> Handle
}


public struct AsyncSubscribingSequence<S: Subscribable>: AsyncSequence {
    public typealias AsyncIterator = AsyncStream<Element>.AsyncIterator
    
    public typealias Element = S.Event
    
    private var source: Source
    
    public init(_ subscribable: S) {
        self.source = .stream(Self.createAsyncStream(subscribable))
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        switch self.source {
        case let .stream(stream):
            return stream.makeAsyncIterator()
        case let .iterator(iterator):
            return iterator
        }
    }
    
    @discardableResult
    public mutating func connect() -> AsyncIterator {
        switch self.source {
        case let .stream(stream):
            let iterator = stream.makeAsyncIterator()
            self.source = .iterator(iterator)
            return iterator
        case let .iterator(iterator):
            return iterator
        }
    }
    
    enum Source {
        case stream(AsyncStream<Element>)
        case iterator(AsyncStream<Element>.AsyncIterator)
    }
    
    private static func createAsyncStream<S: Subscribable>(_ subscribable: S) -> AsyncStream<S.Event> {
        AsyncStream(S.Event.self) { continuation in
            var handle: S.Handle?
            _ = handle // ignore never read warning
            
            
            handle = subscribable.register { event in
                if event.isCompletion {
                    handle = nil
                    continuation.finish()
                } else {
                    continuation.yield(event)
                }
            }
        }
    }
}
