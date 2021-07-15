//
//  ConvenienceFunctions.swift
//  
//
//  Created by Max Obermeier on 12.07.21.
//

import _Concurrency
import NIO
import _NIOConcurrency

public extension AsyncSequence {
    func append<Tail>(_ tail: Tail) -> AnyAsyncSequence<Self.Element> where Tail: AsyncSequence, Self.Element == Tail.Element {
        [self.typeErased, tail.typeErased].asAsyncSequence.flatMap { $0 }.typeErased
    }
}

public extension AsyncSequence {
    func collect() -> Just<[Element]> {
        Just({ try await self.reduce(into: [Element](), { result, element in
            result.append(element)
        })})
    }
}

public extension AsyncSequence {
    func firstFuture(on eventLoop: EventLoop) -> EventLoopFuture<Element?> {
        let promise = eventLoop.makePromise(of: Element?.self)
        
        promise.completeWithAsync {
            try await self.first(where: { _ in true })
        }
    
        return promise.futureResult
    }
}
