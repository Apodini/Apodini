//
//  StatefulEvaluation.swift
//  
//
//  Created by Max Obermeier on 21.06.21.
//

import Apodini
import OpenCombine
import Foundation
import _Concurrency


// MARK: Handling Subscription

extension Delegate: Subscribable { }

extension TriggerEvent: CompletionCandidate {
    public var isCompletion: Bool { false }
}

public extension AsyncSequence where Element: Request {
    func subscribe<H: Handler>(to handler: inout Delegate<H>) -> AsyncMergeSequence<AnyAsyncSequence<Event>, AnyAsyncSequence<Event>> {
        _Internal.prepareIfNotReady(&handler)
        
        let handler = handler
        
        let upstream: AnyAsyncSequence<Event> = self.map { (request: Request) -> Event in
            Event.request(request)
        }
        .append([Event.end].asAsyncSequence)
        .typeErased
        
        let observations: AnyAsyncSequence<Event> = AsyncSubscribingSequence(handler).map { triggerEvent in
            Event.trigger(triggerEvent)
        }
        .typeErased
        
        return upstream.merge(with: observations)
    }
}


public extension Publisher where Output: Request {
    /// A `Publisher` that takes care of subscribing to `TriggerEvent`s emitted
    /// by the given `Delegate` as well as converting the upstream's `Request`s to
    /// `Event`s.
    ///
    /// In detail, this `Publisher` does four things:
    ///     - it maps all upstream `Request`s to an ``Event/request(_:)``
    ///     - if successful (`finished`), it maps the upstream's completion to an
    ///     ``Event/end``
    ///     - it subscribes to `TriggerEvent`s produced by the given `handler`
    ///     and maps them to a ``Event/trigger(_:)``
    ///     - when its ``CancellablePublisher/cancel()`` function is called,
    ///     it cancels the subscription to the `handler` and sends a completion downstream
    ///
    /// - Note: This `Publisher` causes unlimited demand on the `upstream` pipeline.
    func subscribe<H: Handler>(to handler: inout Delegate<H>) -> CancellablePublisher<AnyPublisher<Event, Failure>> {
        _Internal.prepareIfNotReady(&handler)
        
        let handler = handler

        let subject = PassthroughSubject<Event, Failure>()

        var observation: Observation?

        observation = handler.register { trigger in
            subject.send(.trigger(trigger))
        }

        var cancellables: Set<AnyCancellable> = []

        let downstream = subject
            .eagerBuffer()
            .filter { _ in observation != nil }
            .eraseToAnyPublisher()
            .asCancellable {
                subject.send(completion: .finished)
                observation = nil
                cancellables.removeAll()
            }
        
        self.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                subject.send(.end)
            default:
                subject.send(completion: completion)
            }
        }, receiveValue: { request in
            subject.send(.request(request))
        })
        .store(in: &cancellables)
        
        return downstream
    }
}

/// A `Publisher` that also is a `Cancellable`.
///
/// The ``CancellablePublisher`` wraps a given `Publisher` `P` and
/// calls a given callback when its ``cancel()`` function is executed.
public struct CancellablePublisher<P: Publisher>: Publisher, Cancellable {
    internal init(cancelCallback: @escaping () -> Void, publisher: P) {
        self.cancelCallback = cancelCallback
        self._publisher = publisher
    }
    
    public typealias Output = P.Output
    
    public typealias Failure = P.Failure
    
    private let cancelCallback: () -> Void
    
    private let _publisher: P
    
    public func receive<Subscriber: OpenCombine.Subscriber>(subscriber: Subscriber)
        where P.Failure == Subscriber.Failure, P.Output == Subscriber.Input {
        _publisher.receive(subscriber: subscriber)
    }
    
    public func cancel() {
        cancelCallback()
    }
}

extension Publisher {
    /// Wraps this `Publisher` into a ``CancellablePublisher`` that executes the given
    /// `callback` when cancelled.
    public func asCancellable(_ callback: @escaping () -> Void) -> CancellablePublisher<Self> {
        CancellablePublisher(cancelCallback: callback, publisher: self)
    }
}


// MARK: Handling Event Evaluation

public extension AsyncSequence where Element == Event {
    func evaluate<H: Handler>(on handler: inout Delegate<H>) -> AnyAsyncSequence<Result<Response<H.Response.Content>, Error>> {
        _Internal.prepareIfNotReady(&handler)
        let handler = handler
        
        var latestRequest: Request?
        
        var connectionState = ConnectionState.open
        
        return self
        .map { event in
            switch event {
            case .end:
                connectionState = .end
                if let request = latestRequest {
                    return .request(request)
                } else {
                    return .end
                }
            default:
                return event
            }
        }
        .compactMap { (event: Event) async throws -> Result<Response<H.Response.Content>, Error>? in
            switch event {
            case let .request(request):
                latestRequest = request
                do {
                    return .success(try await handler.evaluate(using: request, with: connectionState))
                } catch {
                    return .failure(error)
                }
            case let .trigger(trigger):
                guard let request = latestRequest else {
                    fatalError("Cannot handle TriggerEvent before first Request!")
                }
                
                do {
                    return .success(try await handler.evaluate(trigger, using: request, with: connectionState))
                } catch {
                    return .failure(error)
                }
            case .end:
                return nil
            }
        }
        .typeErased
    }
}



extension CancellablePublisher where Output == Event {
    /// A `Publisher` that consumes the incoming ``Event``s and publishes
    /// a `Result` for each evaluation of the `handler` containing the `Response`
    /// if successful.
    ///
    /// In detail, this `Publisher` does four things:
    ///     - it evaluates each incoming ``Event/request(_:)`` returning the result
    ///     and keeps a copy of the latest `Request` instance
    ///     - when receiving an ``Event/end``, it switches the internal `ConnectionState`
    ///       to `end` and evaluates the `handler` with this new state and the latest `Request`
    ///     - when receiving an ``Event/trigger(_:)`` it evaluates the `handler` with
    ///     the current `ConnectionState` and the latest `Request`
    ///     - when its ``CancellablePublisher/cancel()`` function is called,
    ///     it forwards the call to its upstream.
    ///
    /// - Warning: If the sequence of ``Event``s coming from the upstream `Publisher`
    /// does not follow rules for a valid sequence of ``Event``s as defined on ``Event``, the
    /// `Publisher` might crash at runtime.
    public func evaluate<H: Handler>(on handler: inout Delegate<H>)
        -> CancellablePublisher<AnyPublisher<Result<Response<H.Response.Content>, Error>, Self.Failure>> {
        var lastRequest: Request?
        _Internal.prepareIfNotReady(&handler)
        let preparedHandler = handler
        
        var connectionState = ConnectionState.open
        
        return self
        .compactMap { event in
            switch event {
            case .end:
                connectionState = .end
                if let request = lastRequest {
                    return .request(request)
                } else {
                    return nil
                }
            default:
                return event
            }
        }
        .syncMap { (event: Event) -> EventLoopFuture<Response<H.Response.Content>> in
            switch event {
            case let .request(request):
                lastRequest = request
                return preparedHandler.evaluate(using: request, with: connectionState)
            case let .trigger(trigger):
                guard let request = lastRequest else {
                    fatalError("Cannot handle TriggerEvent before first Request!")
                }
                
                return preparedHandler.evaluate(trigger, using: request, with: connectionState)
            case .end:
                fatalError("Handled above!")
            }
        }
        .eraseToAnyPublisher()
        .asCancellable {
            self.cancel()
        }
    }
}

extension CancellablePublisher {
    /// A `Publisher` that calls this cancellable's ``CancellablePublisher/cancel()`` method
    /// if the given `condition` evaluates to `true`.
    public func cancel(if condition: @escaping (Output) -> Bool) -> OpenCombine.Publishers.Map<Self, Output> {
        self.map { (value: Output) -> Output in
            if condition(value) {
                self.cancel()
            }
            return value
        }
    }
}


// MARK: Handling Pure Request Evaluation

extension Publisher where Output: Request {
    func evaluate<H: Handler>(on handler: inout Delegate<H>) -> Publishers.SyncMap<Self, Response<H.Response.Content>> {
        _Internal.prepareIfNotReady(&handler)
        let preparedHandler = handler
        
        return self.syncMap { request in
            preparedHandler.evaluate(using: request, with: .open)
        }
    }
    
    func evaluateAndReturnRequest<H: Handler>(on handler: inout Delegate<H>) -> Publishers.SyncMap<Self, ResponseWithRequest<H.Response.Content>> {
        _Internal.prepareIfNotReady(&handler)
        let preparedHandler = handler
        
        return self.syncMap { request in
            preparedHandler.evaluate(using: request, with: .open).map { (response: Response<H.Response.Content>) in
                ResponseWithRequest(response: response, request: request)
            }
        }
    }
}
