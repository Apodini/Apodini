//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import _Concurrency

public struct Just<Element>: AsyncSequence {
    public typealias AsyncIterator = AsyncIteratorImpl
    
    let closure: () async throws -> Element?
    
    init(_ closure: @escaping () async throws -> Element?) {
        self.closure = closure
    }
    
    init(_ closure: @escaping () async throws -> Element) {
        self.closure = {
            try await closure()
        }
    }
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        AsyncIteratorImpl(closure: closure)
    }
}

extension Just {
    public struct AsyncIteratorImpl: AsyncIteratorProtocol {
        var closure: (() async throws -> Element?)?
        
        public mutating func next() async throws -> Element? {
            if let closure = closure {
                self.closure = nil
                return try await closure()
            }
            
            return nil
        }
    }
}
