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
    func reduce() -> some Publisher where Output.Input == Output {
        var last: Output?
        
        return self.map { (new : Output) -> Output in
            let result = last?.reduce(with: new) ?? new
            last = result
            return result
        }
    }
}

public extension Publisher {
    func reduce<R: Reducible>(with initial: R) -> some Publisher where Output == R.Input {
        var last: R = initial
        
        return self.map { (new : Output) -> R in
            let result = last.reduce(with: new)
            last = result
            return result
        }
    }
}


// MARK: Handling Initialization

public extension Publisher where Output: Request {
    func attach<H: Handler>(on handler: H) -> some WithDelegate {
        self.withDelegate(.standaloneInstance(of: handler))
    }
}


// MARK: Handling Subscription

public extension WithDelegate where Output: Request {

    func subscribe<H: Handler>(to handler: H) -> some WithDelegate {
        let subject = PassthroughSubject<Event, Failure>()
        let observation = delegate.register { trigger in
            subject.send(.trigger(trigger))
        }

        return self
            .map { request in
                _ = observation // this keeps `observation` from being deallocated
                return Event.request(request)
            }
            .mergeValues(of: subject)
            .withDelegate(delegate)
    }
}


// MARK: Handling Event Evaluation

public extension WithDelegate where Output == Event {
    func evaluate() -> some WithDelegate {
        self.evaluate(on: delegate).withDelegate(delegate)
    }
}

private extension Publisher where Output == Event {
    func evaluate<H: Handler>(on delegate: Delegate<H>) -> some Publisher {
        var lastRequest: Request?

        return self.syncMap { (event: Event) -> EventLoopFuture<Response<H.Response.Content>> in
            switch event {
            case let .request(request):
                lastRequest = request
                return delegate.evaluate(using: request)
            case let .trigger(trigger):
                guard let request = lastRequest else {
                    fatalError("Can only handle changes to observed object after an initial client-request")
                }
                return delegate.evaluate(trigger, using: request)
            }
        }
    }
}


// MARK: Handling Request Evaluation

public extension WithDelegate where Output: Request {
    func evaluate() -> Publishers.SyncMap<Self, Response<H.Response.Content>> {
        self.evaluate(on: delegate)
    }
    
    func evaluate() -> Publishers.SyncMap<Self, ResponseWithRequest<H.Response.Content>> {
        self.evaluateAndReturnRequest(on: self.delegate)
    }
}

private extension Publisher where Output: Request {
    func evaluate<H: Handler>(on delegate: Delegate<H>) -> Publishers.SyncMap<Self, Response<H.Response.Content>> {
        return self.syncMap { request in
            delegate.evaluate(using: request)
        }
    }
    
    func evaluateAndReturnRequest<H: Handler>(on delegate: Delegate<H>) -> Publishers.SyncMap<Self, ResponseWithRequest<H.Response.Content>> {
        return self.syncMap { request in
            delegate.evaluate(using: request).map { (response: Response<H.Response.Content>) in
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

// MARK: WithDelegate

public protocol WithDelegate: Publisher {
    associatedtype H: Handler
    var delegate: Delegate<H> { get }
}

struct PublisherWithDelegate<P: Publisher, H: Handler>: WithDelegate {
    typealias Output = P.Output
    
    typealias Failure = P.Failure
    
    private let wrapped: P
    
    let delegate: Delegate<H>
    
    internal init(wrapped: P, delegate: Delegate<H>) {
        self.wrapped = wrapped
        self.delegate = delegate
    }
    
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        wrapped.receive(subscriber: subscriber)
    }
}

extension Publisher {
    func withDelegate<H: Handler>(_ delegate: Delegate<H>) -> PublisherWithDelegate<Self, H> {
        PublisherWithDelegate(wrapped: self, delegate: delegate)
    }
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

public protocol Initializable {
    associatedtype InitialInput
    
    init(_ initial: InitialInput)
}

extension Optional: Reducible where Wrapped: Reducible, Wrapped: Initializable, Wrapped.Input == Wrapped.InitialInput {
    public typealias Input = Wrapped.Input
    
    public func reduce(with new: Input) -> Optional<Wrapped> {
        self?.reduce(with: new) ?? Wrapped(new)
    }
}
