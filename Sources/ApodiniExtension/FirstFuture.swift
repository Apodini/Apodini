//
//  FirstFuture.swift
//  
//
//  Created by Max Obermeier on 23.06.21.
//

import OpenCombine
import NIO


public extension Publisher {
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
