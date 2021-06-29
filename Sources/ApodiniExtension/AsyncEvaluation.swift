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
    func subscribe<H: Handler>(to handler: inout Delegate<H>) -> CancellablePublisher<AnyPublisher<Event, Failure>> {
        _Internal.prepareIfNotReady(&handler)
        
        let subject = PassthroughSubject<Event, Failure>()
        let completionEventSubject = PassthroughSubject<Event, Failure>()
        
        var observation: Observation?
        
        observation = handler.register { trigger in
            subject.send(.trigger(trigger))
        }
        
        return [subject.buffer(size: Int.max, prefetch: .keepFull, whenFull: .dropNewest).eraseToAnyPublisher(),
                self
                    .handleEvents(receiveCompletion: { _ in
                        completionEventSubject.send(Event.update(.end))
                    })
                    .map { request in
                        Event.request(request)
                    }
                    .eraseToAnyPublisher(),
                completionEventSubject.eraseToAnyPublisher()
        ].publisher.flatMap { publisher in publisher }
        .filter { _ in observation != nil }
        .eraseToAnyPublisher()
        .asCancellable {
            subject.send(completion: .finished)
            completionEventSubject.send(completion: .finished)
            observation = nil
        }
    }
}


public struct CancellablePublisher<P: Publisher>: Publisher, Cancellable {
    internal init(cancelCallback: @escaping () -> Void, _publisher: P) {
        self.cancelCallback = cancelCallback
        self._publisher = _publisher
    }
    
    public typealias Output = P.Output
    
    public typealias Failure = P.Failure
    
    private let cancelCallback: () -> Void
    
    private let _publisher: P
    
    public func receive<Subscriber: OpenCombine.Subscriber>(subscriber: Subscriber) where P.Failure == Subscriber.Failure, P.Output == Subscriber.Input {
        _publisher.receive(subscriber: subscriber)
    }
    
    public func cancel() {
        cancelCallback()
    }
}

extension Publisher {
    public func asCancellable(_ callback: @escaping () -> Void) -> CancellablePublisher<Self> {
        CancellablePublisher(cancelCallback: callback, _publisher: self)
    }
}


// MARK: Handling Event Evaluation

public protocol ErrorHandler {
    associatedtype Output
    associatedtype Failure
    
    func handle(_ error: ApodiniError) -> ErrorHandlingStrategy<Output, Failure>
}

public enum ErrorHandlingStrategy<Output, Failure> {
    case graceful(Output)
    case ignore
    case abort(Failure)
}

extension CancellablePublisher where Output == Event {
    public func evaluate<H: Handler>(on handler: inout Delegate<H>) -> CancellablePublisher<AnyPublisher<Result<Response<H.Response.Content>, Error>, Self.Failure>> {
        var lastRequest: Request?
        _Internal.prepareIfNotReady(&handler)
        let preparedHandler = handler
        
        var connectionState = ConnectionState.open
        
        var wasEvaluatedWithConnectionStateEnd = false
        
        return self
        .compactMap { event in
            switch event {
            case let .update(state):
                connectionState = state
                if let request = lastRequest, !wasEvaluatedWithConnectionStateEnd {
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
                wasEvaluatedWithConnectionStateEnd = connectionState == .end
                lastRequest = request
                return preparedHandler.evaluate(using: request, with: connectionState)
            case let .trigger(trigger):
                wasEvaluatedWithConnectionStateEnd = connectionState == .end
                guard let request = lastRequest else {
                    fatalError("Cannot handle TriggerEvent before first Request!")
                }
                
                return preparedHandler.evaluate(trigger, using: request, with: connectionState)
            case .update(_):
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
    public func cancel(if condition: @escaping (Output) -> Bool) -> OpenCombine.Publishers.Map<Self, Output> {
        return self.map { (value: Output) -> Output in
            if condition(value) {
                self.cancel()
            }
            return value
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
    case update(ConnectionState)
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
