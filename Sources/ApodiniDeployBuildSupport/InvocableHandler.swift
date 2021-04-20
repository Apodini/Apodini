//
//  InvocableHandler.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-14.
//

import Apodini

// MARK: InvocableHandler

/// An `InvocableHandler` is a `Handler` which can be invoked from within another handler's `handle()` function.
/// - [Reference](https://github.com/Apodini/Apodini/blob/develop/Documentation/Components/Inter-Component%20Communication.md)
public protocol InvocableHandler: IdentifiableHandler where Self.Response.Content: Decodable {
    /// The protocol a custom arguments storage type has to conform to
    typealias ArgumentsStorageProtocol = InvocableHandlerArgumentsStorageProtocol
    /// The type of this handler's arguments storage object
    associatedtype ArgumentsStorage: ArgumentsStorageProtocol
        = InvocableHandlerEmptyArgumentsStorage<Self> where ArgumentsStorage.HandlerType == Self
}


// MARK: Supporting Types


/// The protocol used to define an `InvocableHandler`'s arguments type
public protocol InvocableHandlerArgumentsStorageProtocol {
    /// The type of the handler for which this arguments storage object stores arguments
    associatedtype HandlerType: InvocableHandler
    /// Type of the `mapping` array's elements
    typealias MappingEntry = HandlerArgumentsStorageMappingEntry<Self, HandlerType>
    
    /// `MappingEntry` objects for each mapping from one of this type's properties to the corresponding `@Parameter` property in `HandlerType`
    static var mapping: [MappingEntry] { get }
}


/// A default arguments storage for `InvocableHandler`s which do not specify their own storage type.
public struct InvocableHandlerEmptyArgumentsStorage<HandlerType: InvocableHandler>: InvocableHandler.ArgumentsStorageProtocol {
    public typealias HandlerType = HandlerType
    public static var mapping: [MappingEntry] { [] }
    private init() {}
}


/// Helper type which is used for mapping an argument value in an `InvocableHandler`'s argument storage type to the handler's `@Parameter` object this argument belongs to.
public struct HandlerArgumentsStorageMappingEntry<ArgsStruct: InvocableHandler.ArgumentsStorageProtocol, Handler: InvocableHandler> {
    /// key path into the `Handler.ArgumentsStorage` struct, to this argument's value
    public let argsStructKeyPath: PartialKeyPath<ArgsStruct>
    /// key path into the `Handler` struct, to this argument's `Parameter<>.ID`
    public let handlerKeyPath: PartialKeyPath<Handler>

    /// Create a mapping entry from a property in an `InvocableHandler`'s arguments storage type to the handler's corresponding `@Parameter` property
    public init<Value>(
        from argsStructKeyPath: KeyPath<ArgsStruct, Value>,
        to handlerKeyPath: KeyPath<Handler, Binding<Value>>
    ) {
        self.argsStructKeyPath = argsStructKeyPath
        self.handlerKeyPath = handlerKeyPath
    }
}
