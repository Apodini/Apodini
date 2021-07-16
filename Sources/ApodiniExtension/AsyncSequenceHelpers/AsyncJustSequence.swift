//
//  AsyncJustSequence.swift
//  
//
//  Created by Max Obermeier on 12.07.21.
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
