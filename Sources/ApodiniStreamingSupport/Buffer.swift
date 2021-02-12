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
    /// A buffer that subscribes with unlimited demand to its upstream while keeping a given
    /// amount of _events_ in memory until the downstream publisher is ready to receive them.
    /// - Parameter amount: The number of events that are buffered. If `nil`, the buffer is
    ///   of unlimited size.
    ///
    /// - Note: An _event_ can be either a `completion` or `value`. Both are buffered, i.e.
    ///   a `completion` is not forwarded instantly, but after the `value` the `Buffer` received
    ///   it after.
    /// - Note: While `value`s may be dropped if the buffer is full, the `completion` is never
    ///   discarded.
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
    final class Inner<Downstream: Subscriber>: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible
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
        // Instantly request `unlimited` input. If the
        // downstream requests new demand, try to satisfy it
        // from the buffer. If the downstream is canceled,
        // forward cancellation to the upstream instantly.
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

        // Add the `value` to the `buffer` and satisfy downstream's
        // `demand` if applicable.
        func receive(_ input: Input) -> Subscribers.Demand {
            self.lock.lock()
            defer { self.lock.unlock() }
            
            self.removeOverflow()
                        
            self.buffer.append(.value(input))
            
            self.satisfyDemand()
            
            return .unlimited
        }

        // Add the `completion` to the `buffer` and satisfy downstream's
        // `demand` if applicable.
        func receive(completion: Subscribers.Completion<Failure>) {
            self.lock.lock()
            defer { self.lock.unlock() }
            
            self.removeOverflow()
            
            self.buffer.append(.completion(completion))
            
            self.satisfyDemand()
        }
        
        // Make room for one element. If an element has to be dropped, make
        // sure it is a `value`, not a `completion`.
        func removeOverflow() {
            if let size = bufferSize {
                if self.buffer.count == size {
                    if let index = self.buffer.firstIndex(where: { event in
                        switch event {
                        case .completion:
                            return false
                        case .value:
                            return true
                        }
                    }) {
                        buffer.remove(at: index)
                    }
                }
            }
        }
        
        // Pass `value`s to the downstream until its `demand` is satisfied.
        // If we find a `completion` we are done and free our memory.
        func satisfyDemand() {
            outer: while self.demand > 0 && !self.buffer.isEmpty {
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
    // The subscription only forwards the interaction with the downstream to the
    // `Buffer`'s `Subscriber`.
    private class Inner: Subscription {
        var onRequest: ((Subscribers.Demand) -> Void)?
        var onCancel: (() -> Void)?

        init(onRequest: @escaping (Subscribers.Demand) -> Void, onCancel: @escaping () -> Void) {
            self.onRequest = onRequest
            self.onCancel = onCancel
        }

        private let lock = NSRecursiveLock()

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
