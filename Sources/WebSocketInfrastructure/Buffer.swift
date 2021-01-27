//
//  Buffer.swift
//
//
//  Created by Max Obermeier on 27.01.21.
//

import OpenCombine
import NIO
import Foundation

public extension Publisher {
    func buffer(
        _ amount: UInt? = nil
    ) -> Buffer<Self> {
        Buffer(upstream: self, size: amount)
    }
}

/// The `Publisher` behind `Publisher.buffer`.
public struct Buffer<Upstream: Publisher>: Publisher {
    public typealias Failure = Upstream.Failure
    
    public typealias Output = Upstream.Output

    /// The publisher from which this publisher receives elements.
    private let upstream: Upstream

    
    private let size: UInt?

    internal init(upstream: Upstream,
                  size: UInt?) {
        self.upstream = upstream
        self.size = size
    }

    public func receive<Downstream: Subscriber>(subscriber: Downstream)
    where Output == Downstream.Input, Downstream.Failure == Failure {
        upstream.subscribe(Inner(downstream: subscriber, bufferSize: size))
    }
}


private extension Buffer {
    class Inner<Downstream: Subscriber>: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible
    where Downstream.Input == Output, Downstream.Failure == Failure {
        typealias Input = Upstream.Output

        typealias Failure = Downstream.Failure

        private let downstream: Downstream
        
        private var subscription: Subscription?

        private let bufferSize: UInt?
        
        private let lock = NSRecursiveLock()
        
        private var buffer: [Event] = []
        
        private var demand: Subscribers.Demand = .none

        let combineIdentifier = CombineIdentifier()

        fileprivate init(downstream: Downstream, bufferSize: UInt?) {
            self.downstream = downstream
            self.bufferSize = bufferSize
        }

        func receive(subscription: Subscription) {
            subscription.request(.unlimited)
            self.subscription = subscription
            downstream.receive(subscription: Inner(onRequest: { demand in
                self.lock.lock()
                defer { self.lock.unlock() }
                self.demand += demand
                self.satisfyDemand()
            }, onCancel: {
                self.lock.lock()
                self.subscription?.cancel()
                self.subscription = nil
                self.lock.unlock()
            }))
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            self.lock.lock()
            defer { self.lock.unlock() }
            
            self.removeOverflow()
                        
            self.buffer.append(.value(input))
            
            self.satisfyDemand()
            
            return .unlimited
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            self.lock.lock()
            defer { self.lock.unlock() }
            
            self.removeOverflow()
            
            self.buffer.append(.completion(completion))
            
            self.satisfyDemand()
        }
        
        func removeOverflow() {
            if let size = bufferSize {
                if self.buffer.count == size {
                    if let index = self.buffer.firstIndex(where: { event in
                        switch event {
                        case .completion(_):
                            return false
                        case .value(_):
                            return true
                        }
                    }) {
                        buffer.remove(at: index)
                    }
                }
            }
        }
        
        func satisfyDemand() {
            outer: while self.demand > 0 && self.buffer.count > 0 {
                self.demand -= 1
                switch self.buffer.removeFirst() {
                case .value(let value):
                    self.demand += self.downstream.receive(value)
                case .completion(let completion):
                    self.downstream.receive(completion: completion)
                    self.subscription = nil
                    break outer
                }
            }
        }

        var description: String { "Buffer" }

        var playgroundDescription: Any { description }
    }
}

private extension Buffer.Inner {
    private enum Event {
        case completion(Subscribers.Completion<Failure>)
        case value(Input)
    }
}


private extension Buffer.Inner {
    private class Inner: Subscription {
        var onRequest: ((Subscribers.Demand) -> Void)?
        var onCancel: (() -> Void)?

        init(onRequest: @escaping (Subscribers.Demand) -> Void, onCancel: @escaping () -> Void) {
            self.onRequest = onRequest
            self.onCancel = onCancel
        }

        private let lock = NSLock()

        func request(_ demand: Subscribers.Demand) {
            self.lock.lock()
            onRequest?(demand)
            self.lock.unlock()
        }

        func cancel() {
            self.lock.lock()
            onCancel?()
            onCancel = nil
            onRequest = nil
            self.lock.unlock()
        }
    }
}
