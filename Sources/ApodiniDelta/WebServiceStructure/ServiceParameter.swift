//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Foundation

extension ParameterType: ComparableProperty {}
extension Necessity: ComparableProperty {}

class ParameterName: PropertyValueWrapper<String> {}
class NilIsValidValue: PropertyValueWrapper<Bool> {}

/// Represents a parameter of an endpoint
struct ServiceParameter: Codable {
    /// Name of the parameter
    let parameterName: ParameterName

    /// The necessity of the parameter
    let necessity: Necessity

    /// Parameter type
    let type: ParameterType

    /// Indicates whether `nil` is a valid value
    let nilIsValidValue: NilIsValidValue

    /// Schema name of the type of the parameter
    let schemaName: SchemaName
}

// MARK: - Array extension
extension Array where Element == AnyEndpointParameter {
    func serviceParameters(with builder: inout SchemaBuilder) -> [ServiceParameter] {
        map {
            let schemaName = builder.build(for: $0.propertyType) ?? .empty
            return ServiceParameter(
                parameterName: .init($0.name),
                necessity: $0.necessity,
                type: $0.parameterType,
                nilIsValidValue: .init($0.nilIsValidValue),
                schemaName: schemaName
            )
        }
    }
}

// MARK: - ComparableObject
extension ServiceParameter: ComparableObject {
    var deltaIdentifier: DeltaIdentifier {
        .init(parameterName.value)
    }

    func compare(to other: ServiceParameter) -> ChangeContextNode {
        ChangeContextNode()
            .register(compare(\.parameterName, with: other), for: ParameterName.self)
            .register(compare(\.necessity, with: other), for: Necessity.self)
            .register(compare(\.type, with: other), for: ParameterType.self)
            .register(compare(\.nilIsValidValue, with: other), for: NilIsValidValue.self)
            .register(compare(\.schemaName, with: other), for: SchemaName.self)
    }

    func evaluate(result: ChangeContextNode, embeddedInCollection: Bool) -> Change? {
        guard let context = context(from: result, embeddedInCollection: embeddedInCollection) else {
            return nil
        }

        let changes = [
            parameterName.change(in: context),
            necessity.change(in: context),
            type.change(in: context),
            nilIsValidValue.change(in: context),
            schemaName.change(in: context)
        ].compactMap { $0 }

        guard !changes.isEmpty else {
            return nil
        }

        return .compositeChange(location: Self.changeLocation, changes: changes)
    }
}
