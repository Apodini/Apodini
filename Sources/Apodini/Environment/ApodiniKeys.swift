//
//  File.swift
//  
//
//  Created by Alexander Collins on 30.12.20.
//

public protocol ApodiniKeyCollection {
    associatedtype KeyStore: ApodiniKeys = EmptyKeyStore
}

extension ApodiniKeyCollection { }

public protocol ApodiniKeys { }

public struct EmptyKeyStore: ApodiniKeys { }
