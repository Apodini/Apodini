//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension AsyncSequence {
    /// Emits the first element of the upstream sequence. Throws the given error if there is more than one element.
    public func firstAndThenError(_ error: any Error) -> AsyncFirstAndThenErrorSequence<Self> {
        AsyncFirstAndThenErrorSequence(upstream: self, error: error)
    }
}

/// Emits the first element of the upstream sequence. Throws the given error if there is more than one element.
public struct AsyncFirstAndThenErrorSequence<Upstream: AsyncSequence>: AsyncSequence {
    public typealias Element = Upstream.Element
    public typealias AsyncIterator = AsyncIteratorImpl
    
    let upstream: Upstream
    let error: any Error
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        AsyncIteratorImpl(upstreamIt: upstream.makeAsyncIterator(), error: error)
    }
}

/// Emits the first element of the upstream sequence. Throws the given error if there is more than one element.
public extension AsyncFirstAndThenErrorSequence {
    struct AsyncIteratorImpl: AsyncIteratorProtocol {
        var upstreamIt: Upstream.AsyncIterator?
        var error: any Error
        
        var hadFirst = false
        
        public mutating func next() async throws -> Element? {
            if hadFirst {
                if try await upstreamIt?.next() != nil {
                    // We've found a second element, throw error
                    upstreamIt = nil
                    throw error
                }
                upstreamIt = nil
                return nil
            }
            if let result = try await upstreamIt?.next() {
                hadFirst = true
                return result
            } else {
                // upstream is empty, so this sequence will be too
                upstreamIt = nil
                return nil
            }
        }
    }
}
