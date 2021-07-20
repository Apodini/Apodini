//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import _Concurrency

extension AnySequence: AsyncSequence {
    public typealias AsyncIterator = AsyncIteratorImpl
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        AsyncIteratorImpl(iterator: self.makeIterator())
    }
}

extension AnySequence {
    public struct AsyncIteratorImpl: AsyncIteratorProtocol {
        var iterator: AnySequence.Iterator
        
        public mutating func next() async throws -> Element? {
            iterator.next()
        }
    }
}

public extension Sequence {
    /// Wraps this `Sequence` in an `AnySequence`, which in turn can be used
    /// as an `AsyncSequence`.
    var asAsyncSequence: AnySequence<Element> {
        AnySequence(self)
    }
}
