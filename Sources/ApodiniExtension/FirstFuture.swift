//
//  FirstFuture.swift
//  
//
//  Created by Max Obermeier on 23.06.21.
//

import OpenCombine
import NIO
import _Concurrency
import _NIOConcurrency

@available(macOS 12.0, *)
public extension AsyncSequence {
    func firstFuture(on eventLoop: EventLoop) -> EventLoopFuture<Element?> {
        let promise = eventLoop.makePromise(of: Element?.self)
        
        promise.completeWithAsync {
            try await self.first(where: { _ in true })
        }
    
        return promise.futureResult
    }
}

public extension Publisher {
    /// Returns an `EventLoopFuture` that is completed with the first value published on this
    /// OpenCombine `Publisher`.
    ///
    /// If the publisher completes with a failure, the future fails with the contained error. If the
    /// publisher completes successfully without ever sending a value, the future is completed
    /// with a value of `nil`.
    func firstFuture(on eventLoop: EventLoop) -> EventLoopFuture<Output?> {
        var cancellables = Set<AnyCancellable>()
        
        let promise = eventLoop.makePromise(of: Output?.self)
        
        var value: Output?
        
        self.first()
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    promise.fail(error)
                } else {
                    promise.succeed(value)
                }
                cancellables.removeAll()
            }, receiveValue: { output in
                value = output
            })
            .store(in: &cancellables)
        
        return promise.futureResult
    }
}
