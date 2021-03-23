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
    /// The protocol a custom parameters storage type has to conform to
    typealias ParametersStorageProtocol = InvocableHandlerParametersStorageProtocol
    /// The type of this handler's parameters storage object
    associatedtype ParametersStorage: ParametersStorageProtocol
        = InvocableHandlerEmptyParametersStorage<Self> where ParametersStorage.HandlerType == Self
}


// MARK: Supporting Types


/// The protocol used to define an `InvocableHandler`'s parameters type
public protocol InvocableHandlerParametersStorageProtocol {
    /// The type of the handler for which this parameters storage object stores parameters
    associatedtype HandlerType: InvocableHandler
    /// Type of the `mapping` array's elements
    typealias MappingEntry = HandlerParametersStorageMappingEntry<Self, HandlerType>
    
    /// `MappingEntry` objects for each mapping from one of this type's properties to the corresponding `@Parameter` property in `HandlerType`
    static var mapping: [MappingEntry] { get }
}


/// A default parameters storage for `InvocableHandler`s which do not specify their own storage type.
public struct InvocableHandlerEmptyParametersStorage<HandlerType: InvocableHandler>: InvocableHandler.ParametersStorageProtocol {
    public typealias HandlerType = HandlerType
    public static var mapping: [MappingEntry] { [] }
    private init() {}
}


/// Helper type which is used for mapping a parameter value in an `InvocableHandler`'s parameter storage type to the handler's `@Parameter` object this parameter belongs to.
public struct HandlerParametersStorageMappingEntry<ParamsStruct: InvocableHandler.ParametersStorageProtocol, Handler: InvocableHandler> {
    /// key path into the `Handler.Prameters` struct, to this parameter's value
    public let paramsStructKeyPath: PartialKeyPath<ParamsStruct>
    /// key path into the `Handler` struct, to this parameter's `Parameter<>.ID`
    public let handlerKeyPath: PartialKeyPath<Handler>

    /// Create a mapping entry from a property in an `InvocableHandler`'s parameter storage type to the handler's corresponding `@Parameter` property
    public init<Value>(
        from paramsStructKeyPath: KeyPath<ParamsStruct, Value>,
        to handlerKeyPath: KeyPath<Handler, Binding<Value>>
    ) {
        self.paramsStructKeyPath = paramsStructKeyPath
        self.handlerKeyPath = handlerKeyPath
    }
}
