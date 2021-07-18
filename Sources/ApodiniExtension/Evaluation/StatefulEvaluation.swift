//
//  StatefulEvaluation.swift
//  
//
//  Created by Max Obermeier on 21.06.21.
//

import Apodini
import Foundation
import _Concurrency


// MARK: Handling Subscription

extension Delegate: Subscribable { }

extension TriggerEvent: CompletionCandidate {
    public var isCompletion: Bool { false }
}

public extension AsyncSequence where Element: Request {
    /// An `AsyncSequence` that takes care of subscribing to `TriggerEvent`s emitted
    /// by the given `Delegate` as well as converting the upstream's `Request`s to
    /// `Event`s.
    ///
    /// In detail, this `AsyncSequence` does three things:
    ///     - it maps all upstream `Request`s to an ``Event/request(_:)``
    ///     - it maps the upstream's end (`nil`)  to an ``Event/end``
    ///     - it subscribes to `TriggerEvent`s produced by the given `handler`
    ///     and maps them to a ``Event/trigger(_:)``
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

// MARK: Handling Event Evaluation

public extension AsyncSequence where Element == Event {
    /// An `AsyncSequence` that consumes the incoming ``Event``s and publishes
    /// a `Result` for each evaluation of the `handler` containing the `Response`
    /// if successful.
    ///
    /// In detail, this `AsyncSequence` does three things:
    ///     - it evaluates each incoming ``Event/request(_:)`` returning the result
    ///     and keeps a copy of the latest `Request` instance
    ///     - when receiving an ``Event/end``, it switches the internal `ConnectionState`
    ///       to `end` and evaluates the `handler` with this new state and the latest `Request`
    ///     - when receiving an ``Event/trigger(_:)`` it evaluates the `handler` with
    ///     the current `ConnectionState` and the latest `Request`
    ///
    /// - Warning: If the sequence of ``Event``s coming from the upstream `AsyncSequence`
    /// does not follow rules for a valid sequence of ``Event``s as defined on ``Event``, the
    /// `AsyncIterator` might crash at runtime.
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
