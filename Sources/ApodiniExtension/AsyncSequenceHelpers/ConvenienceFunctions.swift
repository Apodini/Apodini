//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import NIO

public extension AsyncSequence {
    /// A shorthand for combining this sequence and ``Tail`` using `flatMap`.
    func append<Tail>(_ tail: Tail) -> AnyAsyncSequence<Self.Element> where Tail: AsyncSequence, Self.Element == Tail.Element {
        [self.typeErased, tail.typeErased].asAsyncSequence.flatMap { $0 }.typeErased
    }
}

public extension AsyncSequence {
    /// Returns an `AsyncSequence` that only contains one element. This element is an
    /// `Array` of all `Element` s contained in this sequence.
    func collect() -> Just<[Element]> {
        Just {
            try await self.reduce(into: [Element](), { result, element in
                result.append(element)
            })
        }
    }
}

public extension AsyncSequence {
    /// Returns an `EventLoopFuture` that either completes with the first element available from this
    /// `AsyncSequence`, the error thrown while retrieving the first element, or nil if the sequence is empty.
    func firstFuture(on eventLoop: EventLoop) -> EventLoopFuture<Element?> {
        let promise = eventLoop.makePromise(of: Element?.self)
        promise.completeWithTask {
            try await self.first(where: { _ in true })
        }
        return promise.futureResult
    }
    
    /// Returns an `EventLoopFuture` which will fulfill with the first element in the sequence, and also calls the specified closure once with every element in the sequence
    public func firstFutureAndForEach(on eventLoop: EventLoop, objectsHandler: @escaping (Element) -> Void) -> EventLoopFuture<Element?> {
        let promise = eventLoop.makePromise(of: Element?.self)
        Task {
            var idx = 0
            for try await element in self {
                if idx == 0 {
                    promise.succeed(element)
                }
                idx += 1
                objectsHandler(element)
            }
            if idx == 0 {
                promise.succeed(nil)
            }
        }
        return promise.futureResult
    }
}
