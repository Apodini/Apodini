//
//  Error.swift
//  
//
//  Created by Lukas Kollmer on 16.02.21.
//

public struct ApodiniUtilsError: Swift.Error {
    public let message: String

    internal init(message: String) {
        self.message = message
    }
}
