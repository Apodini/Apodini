//
//  AsyncEvaluation.swift
//  
//
//  Created by Max Obermeier on 21.06.21.
//

import Apodini
import OpenCombine
import Foundation


// MARK: Handling Statefulness

public extension Publisher where Output: Reducible {
    func reduce() -> OpenCombine.Publishers.Map<Self, Output> where Output.Input == Output {
        var last: Output?
        
        return self.map { (new : Output) -> Output in
            let result = last?.reduce(with: new) ?? new
            last = result
            return result
        }
    }
}

public extension Publisher {
    func reduce<R: Initializable>(_ type: R.Type = R.self) -> OpenCombine.Publishers.Map<Self, R> where Output == R.Input {
        var last: R?
        
        return self.map { (new : Output) -> R in
            let result = last?.reduce(with: new) ?? R(new)
            last = result
            return result
        }
    }
}


// MARK: Handling Subscription

public extension Publisher where Output: Request {
    func subscribe<H: Handler>(to handler: inout Delegate<H>, using store: inout Optional<Observation>) -> OpenCombine.Publishers.FlatMap<AnyPublisher<Event, Self.Failure>, OpenCombine.Publishers.SetFailureType<OpenCombine.Publishers.Sequence<Array<AnyPublisher<Event, Self.Failure>>, Never>, AnyPublisher<Event, Self.Failure>.Failure>> {
        _Internal.prepareIfNotReady(&handler)
        
        let subject = PassthroughSubject<Event, Failure>()
        store = handler.register { trigger in
            subject.send(.trigger(trigger))
        }
        
        return [subject.buffer(size: Int.max, prefetch: .keepFull, whenFull: .dropNewest).eraseToAnyPublisher(),
                self.handleEvents(receiveCompletion: { completion in
                    subject.send(completion: .finished)
                }, receiveCancel: {
                    subject.send(completion: .finished)
                }).map { request in
                    return Event.request(request)
                }.eraseToAnyPublisher()
        ].publisher.flatMap { publisher in publisher }
    }
}


// MARK: Handling Event Evaluation

extension Publisher where Output == Event {
    public func evaluate<H: Handler>(on handler: inout Delegate<H>) -> AnyPublisher<Result<Response<H.Response.Content>, Error>, Self.Failure> {
        var lastRequest: Request?
        _Internal.prepareIfNotReady(&handler)
        let preparedHandler = handler
        
        let subject = PassthroughSubject<(Event, ConnectionState), Failure>()
        
        return [self.handleEvents(receiveCompletion: { completion in
            if let finalRequest = lastRequest {
                subject.send((.request(finalRequest), .end))
            }
            subject.send(completion: .finished)
        }).map { event in
            (event, .open)
        }.eraseToAnyPublisher(), subject.eraseToAnyPublisher()]
        .publisher
        .flatMap { publisher in publisher }
        .syncMap { (event: Event, state: ConnectionState) -> EventLoopFuture<Response<H.Response.Content>> in
            switch event {
            case let .request(request):
                lastRequest = request
                return preparedHandler.evaluate(using: request, with: state)
            case let .trigger(trigger):
                guard let request = lastRequest else {
                    fatalError("Can only handle changes to observed object after an initial client-request")
                }
                return preparedHandler.evaluate(trigger, using: request, with: state)
            }
        }.eraseToAnyPublisher()
    }
    
    func evaluate<H: Handler>(on handler: inout Delegate<H>) -> Publishers.SyncMap<Self, Response<H.Response.Content>> {
        var lastRequest: Request?
        _Internal.prepareIfNotReady(&handler)
        let preparedHandler = handler
        
        return self.syncMap { (event: Event) -> EventLoopFuture<Response<H.Response.Content>> in
            switch event {
            case let .request(request):
                lastRequest = request
                return preparedHandler.evaluate(using: request, with: .open)
            case let .trigger(trigger):
                guard let request = lastRequest else {
                    fatalError("Can only handle changes to observed object after an initial client-request")
                }
                return preparedHandler.evaluate(trigger, using: request, with: .open)
            }
        }
    }
}


// MARK: Handling Request Evaluation

public extension Publisher where Output: Request {
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


// MARK: Handling Errors

public extension Publisher {
    func closeOnError<R: ResponseTransformable>() -> some Publisher where Output == Result<R, ApodiniError> {
        self.tryMap { (result: Output) throws -> R in
            switch result {
            case let .failure(error):
                throw error
            case let .success(response):
                return response
            }
        }
    }
}


// MARK: Event

public enum Event {
    case request(Request)
    case trigger(TriggerEvent)
}

// MARK: Reducible

/// An object that can merge itself and a `new` element
/// of same type.
public protocol Reducible {
    associatedtype Input
    
    /// Called to reduce self with the given instance.
    ///
    /// Optional to implement. By default new will overwrite the existing instance.
    ///
    /// - Parameter new: The instance to be combined with.
    /// - Returns: The reduced instance.
    func reduce(with new: Input) -> Self
}

public protocol Initializable: Reducible {
    init(_ initial: Input)
}
