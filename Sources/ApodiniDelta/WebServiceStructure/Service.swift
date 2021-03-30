//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Foundation

extension Apodini.Operation: ComparableProperty {}
class ServicePath: PrimitiveValueWrapper<String> {}
class HandlerName: PrimitiveValueWrapper<String> {}

/// Represents an endpoint
struct Service: Codable {
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

    /// The reference to the schema of the response type of the endpoint
    let response: SchemaReference

    init(
        handlerName: String,
        handlerIdentifier: AnyHandlerIdentifier,
        operation: Apodini.Operation,
        absolutePath: [EndpointPath],
        parameters: [ServiceParameter],
        response: SchemaReference
    ) {
        self.handlerName = .init(handlerName)
        self.handlerIdentifier = handlerIdentifier
        self.operation = operation
        self.absolutePath = .init(absolutePath.asPathString())
        self.parameters = parameters
        self.response = response
    }
}

// MARK: - ComparableObject
extension Service: ComparableObject {
    var deltaIdentifier: DeltaIdentifier { .init(handlerIdentifier.rawValue) }

    func evaluate(result: ChangeContextNode, embeddedInCollection: Bool) -> Change? {
        let context: ChangeContextNode
        if !embeddedInCollection {
            guard let ownContext = result.change(for: Self.self) else { return nil }
            context = ownContext
        } else {
            context = result
        }

        let changes = [
            handlerName.change(in: context),
            operation.change(in: context),
            absolutePath.change(in: context),
            parameters.evaluate(node: context),
            response.change(in: context)
        ].compactMap { $0 }

        guard !changes.isEmpty else { return nil }

        return .compositeChange(location: Self.changeLocation, changes: changes)
    }

    func compare(to other: Service) -> ChangeContextNode {
        let context = ChangeContextNode()

        context.register(compare(\.handlerName, with: other), for: HandlerName.self)
        context.register(compare(\.operation, with: other), for: Apodini.Operation.self)
        context.register(compare(\.absolutePath, with: other), for: ServicePath.self)
        context.register(result: compare(\.parameters, with: other), for: ServiceParameter.self)
        context.register(compare(\.response, with: other), for: SchemaReference.self)

        return context
    }
}
