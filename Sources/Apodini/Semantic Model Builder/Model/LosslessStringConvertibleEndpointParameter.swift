//
//  File.swift
//  
//
//  Created by Nityananda on 07.01.21.
//

protocol LosslessStringConvertibleEndpointParameter {
    /// Initializes a type `T` for which you know that it conforms to `LosslessStringConvertible`.
    ///
    /// - Parameters:
    ///   - description: The Lossless string description for the `type`
    ///   - type: The type used as initializer
    /// - Returns: The result of `LosslessStringConvertible.init(...)`. Nil if the Type couldn't be instantiated for the given `String`
    func initFromDescription<T>(description: String, type: T.Type) -> T?
}

// MARK: - EndpointParameter+LosslessStringConvertibleEndpointParameter

extension EndpointParameter: LosslessStringConvertibleEndpointParameter where Type: LosslessStringConvertible {
    func initFromDescription<T>(description: String, type: T.Type) -> T? {
        guard T.self is Type.Type else {
            fatalError("EndpointParameter.initFromDescription: Tried initializing from LosslessStringConvertible for a T which didn't match the EndpointParameter Type")
        }
        
        // swiftlint:disable:next explicit_init
        let instance = Type.init(description)
        // swiftlint:disable:next force_cast
        return instance as! T?
    }
}
