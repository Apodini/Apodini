//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension AsyncSequence {
    public func firstAndThenError(_ error: Error) -> AsyncFirstAndThenErrorSequence<Self> {
        return AsyncFirstAndThenErrorSequence(upstream: self, error: error)
    }
}

public struct AsyncFirstAndThenErrorSequence<Upstream: AsyncSequence>: AsyncSequence {
    public typealias Element = Upstream.Element
    public typealias AsyncIterator = AsyncIteratorImpl
    
    let upstream: Upstream
    let error: Error
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        AsyncIteratorImpl(upstreamIt: upstream.makeAsyncIterator(), error: error)
    }
}

public extension AsyncFirstAndThenErrorSequence {
    struct AsyncIteratorImpl: AsyncIteratorProtocol {
        var upstreamIt: Upstream.AsyncIterator?
        var error: Error
        
        var hadFirst = false
        
        public mutating func next() async throws -> Element? {
            if hadFirst {
                if let _ = try await upstreamIt?.next() {
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

