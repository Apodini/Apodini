//
//  AsyncSubscribingSequence.swift
//  
//
//  Created by Max Obermeier on 11.07.21.
//

import Foundation
import _Concurrency

/// An element that might signal the completion of a sequence/stream of elements.
public protocol CompletionCandidate {
    /// Returns `true` if this element should be the first to **not** be part of
    /// the sequence/stream.
    var isCompletion: Bool { get }
}

/// An element that allows for registering a closure to be called on certain ``Event``s.
public protocol Subscribable {
    /// The type of events this ``Subscribable`` produces.
    associatedtype Event: CompletionCandidate
    /// The ``Handle`` must be kept by the subscriber until it wants to
    /// cancel the subscription.
    associatedtype Handle
    
    /// The function for registering a callback closure.
    func register(_ callback: @escaping (Event) -> Void) -> Handle
}

/// An `AsyncSequence` that contains the elements published by a ``Subscribable`` source.
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
    
    /// When called, an `AsyncIterator` is created, which will be used by all
    /// subsequent calls to ``makeAsyncIterator()``. If not called, the
    /// ``makeAsyncIterator()`` function creates a new `AsyncIterator``
    /// for each call.
    ///
    /// - Note: Use this function to start buffering elements published by the ``Subscribable``
    /// immediately.
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
