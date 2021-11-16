//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// An `AsyncSequence` that behaves similar to `AsyncPrefixWhileSequence`, but keeps one more
/// element.
public struct AsyncCancelSequence<Base>: AsyncSequence where Base: AsyncSequence {
    public typealias Element = Base.Element
    
    public typealias AsyncIterator = AsyncIteratorImpl
    
    let base: Base
    
    let cancel: (Base.Element) async -> Bool
    
    init(_ base: Base, cancel: @escaping (Base.Element) async -> Bool) {
        self.base = base
        self.cancel = cancel
    }
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        AsyncIteratorImpl(iterator: base.makeAsyncIterator(), cancel: cancel)
    }
}

extension AsyncCancelSequence {
    public struct AsyncIteratorImpl: AsyncIteratorProtocol {
        var iterator: Base.AsyncIterator?
        
        let cancel: (Base.Element) async -> Bool
        
        public mutating func next() async throws -> Element? {
            if let result = try await iterator?.next() {
                if await cancel(result) {
                    iterator = nil
                }
                return result
            }
            iterator = nil
            return nil
        }
    }
}

public extension AsyncSequence {
    /// Returns an asynchronous sequence, containing the initial, consecutive elements of the
    /// base sequence up until (and including) the first for which `cancel` returns `true`.
    func cancelIf(_ predicate: @escaping (Self.Element) async -> Bool) -> AsyncCancelSequence<Self> {
        AsyncCancelSequence(self, cancel: predicate)
    }
}
