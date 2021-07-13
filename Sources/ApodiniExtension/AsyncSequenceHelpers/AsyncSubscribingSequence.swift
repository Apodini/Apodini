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


#warning("'AsyncSubscribingSequence' should be re-written using an 'AsyncStream' once that is available.")
@available(macOS 12.0, *)
public struct AsyncSubscribingSequence<S: Subscribable>: AsyncSequence {
    public typealias AsyncIterator = Self.AsyncIteratorImpl
    
    public typealias Element = S.Event
    
    private var source: Source
    
    public init(_ subscribable: S) {
        self.source = .subscribable(subscribable)
    }
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        switch self.source {
        case let .subscribable(subscribable):
            return AsyncIteratorImpl(subscribable)
        case let .iterator(iterator):
            return iterator
        }
    }
    
    @discardableResult
    public mutating func connect() -> AsyncIteratorImpl {
        switch self.source {
        case let .subscribable(subscribable):
            let iterator = AsyncIteratorImpl(subscribable)
            self.source = .iterator(iterator)
            return iterator
        case let .iterator(iterator):
            return iterator
        }
    }
    
    enum Source {
        case subscribable(S)
        case iterator(AsyncIteratorImpl)
    }
}

@available(macOS 12.0, *)
extension AsyncSubscribingSequence {
    // The construction of this Iterator may seem a bit weird. This has two reasons: for one, the `Storage`'s
    // `receive(event:)` function returns a continuation to be resumed instead of resuming it on its own. The
    // intention of this was to avoid a Swift bug that would have been relevant if `Storage` was an `actor`.
    // The bug causes continuations not to resume from Actor contexts. Thus the struct executes the continuations
    // as given by the `Storage` (see https://bugs.swift.org/browse/SR-14875, https://bugs.swift.org/browse/SR-14841).
    //
    // Now, `Storage` is not an `actor` but a `class`. This is because I do not know of a way to `await` from a
    // synchronous context by blocking execution. If `Storage` were an `actor`, its `receive(event:)` function
    // would be `async`. The only way we could call it from the `subscribable.register`'s callback, would be to
    // launch a `Task` which calls `receive(event:)`. However, this way the order of events could be mixed up,
    // as `Task`s are executed asynchronously. That is the reason `Storage` was implemented as a `class` even though
    // this requires quite some manual locking.
    //
    // The thing is: it works as it is. In the future this whole `AsyncSubscribingSequence` should be replaced by an
    // `AsyncStream` (which has not yet made it into the language) anyways, thus I won't any more time into optimizing
    // this implementation (both in regards to maintainability and performance of the `buffer` implementation.
    //
    // `AsyncStream` Proposal: https://github.com/apple/swift-evolution/blob/main/proposals/0314-async-stream.md
    public struct AsyncIteratorImpl: AsyncIteratorProtocol {
        let storage: Storage
        
        
        init(_ subscribable: S) {
            let storage = Storage()
            storage.setHandle(subscribable.register { event in
                let (continuation, result) = storage.receive(event: event)
                continuation?.resume(returning: result)
            })
            
            self.storage = storage
        }
        
        public func next() async throws -> Element? {
            try await storage.next()
        }
    }
}

@available(macOS 12.0, *)
extension AsyncSubscribingSequence.AsyncIteratorImpl {
    class Storage {
        private var completed = false
        
        private var handle: S.Handle? = nil
        
        private var buffer: [S.Event] = []
        
        private var continuation: CheckedContinuation<S.Event?, Never>? = nil
        
        private let lock = NSLock()
        
        func setHandle(_ handle: S.Handle) {
            lock.lock()
            defer { lock.unlock() }
            if !completed {
                self.handle = handle
            }
        }
        
        func receive(event: S.Event) -> (CheckedContinuation<S.Event?, Never>?, S.Event?) {
            lock.lock()
            defer { lock.unlock() }
            buffer = [event] + buffer
            
            if let continuation = continuation {
                if Task.isCancelled {
                    self.buffer = []
                    self.handle = nil
                    self.continuation = nil
                    self.completed = true
                    return (continuation, nil)
                }
                
                let next = buffer.removeLast()
                if next.isCompletion {
                    self.buffer = []
                    self.handle = nil
                    self.continuation = nil
                    self.completed = true
                    return (continuation, nil)
                } else {
                    self.continuation = nil
                    return (continuation, next)
                }
            }
            return (nil, nil)
        }
        
        public func next() async throws -> S.Event? {
            lock.lock()
            if !buffer.isEmpty {
                lock.unlock()
                return buffer.removeLast()
            }
            
            return await withCheckedContinuation { continuation in
                assert(self.continuation == nil, "'AsyncSubscribingSequence' received a new continuation while the old one was still present!")
                self.continuation = continuation
                lock.unlock()
            }
        }
    }
}
