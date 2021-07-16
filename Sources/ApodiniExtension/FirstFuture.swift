//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import OpenCombine
import NIO


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
