//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Foundation

extension Apodini.Operation: ComparableProperty {}
class ServicePath: PropertyValueWrapper<String> {}
class HandlerName: PropertyValueWrapper<String> {}
class PallidorOperationName: PropertyValueWrapper<String> {}
class PallidorEndpointName: PropertyValueWrapper<String> {}

/// Represents an endpoint
struct Service {
    /// Name of the handler
    let handlerName: HandlerName

    /// Identifier of the handler
    let handlerIdentifier: AnyHandlerIdentifier

    /// The operation of the endpoint
    let operation: Apodini.Operation

    /// The absolute path string of the endpoint
    let absolutePath: ServicePath

    /// Parameters of the endpoint
    let parameters: [ServiceParameter]

    /// Schema name of the response type of the endpoint
    let response: SchemaName
    
    /// Name of the operation specified via `.pallidor(_:)` modified
    let operationName: PallidorOperationName
    
    /// The first path component of the endpoint after dropping the version
    /// e.g. `/v1/users` -> `users`. Used in Pallidor to group endpoints in one file
    let endpointName: PallidorEndpointName

    init(
        handlerName: String,
        handlerIdentifier: AnyHandlerIdentifier,
        operation: Apodini.Operation,
        absolutePath: String,
        parameters: [ServiceParameter],
        response: SchemaName,
        operationName: String,
        endpointName: PallidorEndpointName
    ) {
        self.handlerName = .init(handlerName)
        self.handlerIdentifier = handlerIdentifier
        self.operation = operation
        self.absolutePath = .init(absolutePath)
        self.parameters = parameters
        self.response = response
        self.operationName = .init(operationName)
        self.endpointName = endpointName
    }
}

// MARK: - ComparableObject
extension Service: ComparableObject {
    var deltaIdentifier: DeltaIdentifier { .init(handlerIdentifier) }

    func evaluate(result: ChangeContextNode, embeddedInCollection: Bool) -> Change? {
        guard let context = context(from: result, embeddedInCollection: embeddedInCollection) else {
            return nil
        }

        let changes = [
            handlerName.change(in: context),
            operation.change(in: context),
            absolutePath.change(in: context),
            parameters.evaluate(node: context),
            operationName.change(in: context),
            endpointName.change(in: context),
            response.change(in: context)
        ].compactMap { $0 }

        guard !changes.isEmpty else {
            return nil
        }

        return .compositeChange(location: Self.changeLocation, changes: changes)
    }

    func compare(to other: Service) -> ChangeContextNode {
        ChangeContextNode()
            .register(compare(\.handlerName, with: other), for: HandlerName.self)
            .register(compare(\.operation, with: other), for: Apodini.Operation.self)
            .register(compare(\.absolutePath, with: other), for: ServicePath.self)
            .register(result: compare(\.parameters, with: other), for: ServiceParameter.self)
            .register(compare(\.response, with: other), for: SchemaName.self)
            .register(compare(\.operationName, with: other), for: PallidorOperationName.self)
            .register(compare(\.endpointName, with: other), for: PallidorEndpointName.self)
    }
}
