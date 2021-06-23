//
//  AsyncEvaluation.swift
//  
//
//  Created by Max Obermeier on 21.06.21.
//

import Apodini
import OpenCombine

public extension Publisher where Output: Request {
    #warning("""
        This method would acutally require 'Publishers.Merge', which - at the time of writing - is
        not implemented in OpenCombine (see https://github.com/OpenCombine/OpenCombine/pull/72).
        Thus a combination of 'sink' and 'PassthroughSubject' is used to merge the Publishers.
        However, this results in unlimited upsteam-demand and since downstream-demand might
        be limited, 'PasstroughSubject' might drop elements. To cope with this issue, an unlimited
        'buffer' is used behind the 'PassthroughSubject'!
    """)
    func subscribe<H: Handler>(to handler: H) -> some WithDelegate {
        let delegate = Delegate.standaloneInstance(of: handler)
        
        var subject: PassthroughSubject<Event, Failure>? = PassthroughSubject<Event, Failure>()
        var sink: AnyCancellable?
        var observation: Observation?
        
        // just for silencing "never read" compiler warning
        _ = sink
        _ = observation
        
        sink = self.sink(receiveCompletion: { completion in
            subject!.send(completion: completion)
            subject = nil
            sink = nil
            observation = nil
        }, receiveValue: { request in
            subject!.send(.request(request))
        })
        
        observation = delegate.register { trigger in
            guard let subject = subject else {
                return
            }
            
            subject.send(.trigger(trigger))
        }

        return subject!
            .buffer(size: Int.max, prefetch: .keepFull, whenFull: .dropNewest)
            .withDelegate(delegate)
    }
}

public extension Publisher where Output: Request {
    func attach<H: Handler>(on handler: H) -> some WithDelegate {
        let delegate = Delegate.standaloneInstance(of: handler)
        
        return self
            .withDelegate(delegate)
    }
}

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

public extension WithDelegate where Output: Request {
    func evaluate() -> some WithDelegate {
        self.evaluate(on: delegate).withDelegate(delegate)
    }
}

private extension Publisher where Output: Request {
    func evaluate<H: Handler>(on delegate: Delegate<H>) -> some Publisher {
        return self.syncMap { request in
            delegate.evaluate(using: request)
        }
    }
}

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


// MARK: WithRequest

public protocol WithRequest: Request {
    var request: Request { get }
}


public extension WithRequest {
    var description: String {
        request.description
    }

    var debugDescription: String {
        request.debugDescription
    }

    var eventLoop: EventLoop {
        request.eventLoop
    }

    var remoteAddress: SocketAddress? {
        request.remoteAddress
    }
    
    var information: Set<AnyInformation> {
        request.information
    }

    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element {
        try request.retrieveParameter(parameter)
    }
}

public extension WithRequest {
    func unwrapped<T: Request>(to type: Request.Type = T.self) -> T? {
        if let typed = self as? T {
            return typed
        } else if let withRequest = self.request as? WithRequest {
            return withRequest.unwrapped()
        }
        return nil
    }
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
