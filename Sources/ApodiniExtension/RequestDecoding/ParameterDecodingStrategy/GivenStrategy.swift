//
//  GivenStrategy.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import Apodini


/// A ``ParameterDecodingStrategy`` that ignores its actual input and instead always
/// return the same `element`.
public struct GivenStrategy<E: Decodable, I>: ParameterDecodingStrategy {
    private let element: E
    
    /// Create a new ``GivenStrategy`` that always returns `element`.
    public init(_ element: E) {
        self.element = element
    }
    
    public func decode(from input: I) throws -> E {
        element
    }
}

/// A ``ParameterDecodingStrategy`` that ignores its actual input and instead always
/// throws the same `error`.
public struct ThrowingStrategy<E: Decodable, I>: ParameterDecodingStrategy {
    private let error: Error
    
    /// Create a new ``ThrowingStrategy`` that always throws `error`.
    public init(_ error: Error) {
        self.error = error
    }
    
    public func decode(from input: I) throws -> E {
        throw error
    }
}
