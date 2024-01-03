//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension AsyncSequence {
    /// Passes the elements of this `AsyncSequence` through until an upstream error is caught.
    /// The error can be transformed into an element using `replacer` which ends the sequence.
    public func replaceErrorAndEnd(_ replacer: @escaping (any Error) -> Element?) -> AsyncErrorReplacingSequence<Self> {
        AsyncErrorReplacingSequence(upstream: self, replacer: replacer)
    }
}

/// Passes the elements of the upstream sequence through until an upstream error is caught.
/// The error can be transformed into an element using `replacer` which ends the sequence.
public struct AsyncErrorReplacingSequence<Upstream: AsyncSequence>: AsyncSequence {
    public typealias Element = Upstream.Element
    public typealias AsyncIterator = AsyncIteratorImpl
    
    let upstream: Upstream
    let replacer: (any Error) -> Element?
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        AsyncIteratorImpl(upstreamIt: upstream.makeAsyncIterator(), replacer: replacer)
    }
}

/// Passes upstream elements through and transforms a possible error into a final element.
public extension AsyncErrorReplacingSequence {
    struct AsyncIteratorImpl: AsyncIteratorProtocol {
        var upstreamIt: Upstream.AsyncIterator?
        let replacer: (any Error) -> Element?
        
        public mutating func next() async -> Element? {
            if upstreamIt == nil {
                return nil
            }

            do {
                if let result = try await upstreamIt?.next() {
                    return result
                } else {
                    upstreamIt = nil
                    return nil
                }
            } catch {
                // We've caught an error
                let element = replacer(error)
                upstreamIt = nil
                return element
            }
        }
    }
}
