//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Foundation

class ParameterName: PrimitiveValueWrapper<String>, ComparableProperty {}
class NilIsValidValue: PrimitiveValueWrapper<Bool>, ComparableProperty {}
extension ParameterType: ComparableProperty {}
extension Necessity: ComparableProperty {}

struct ServiceParameter: Codable {

    let parameterName: ParameterName
    let necessity: Necessity
    let type: ParameterType
    let nilIsValidValue: NilIsValidValue
    let schemaReference: SchemaReference
}

extension Array where Element == AnyEndpointParameter {

    func serviceParameters(with builder: inout SchemaBuilder) -> [ServiceParameter] {
        map {
            let reference = builder.build(for: $0.propertyType, root: false) ?? .empty
            return ServiceParameter(
                parameterName: .init($0.name),
                necessity: $0.necessity,
                type: $0.parameterType,
                nilIsValidValue: .init($0.nilIsValidValue),
                schemaReference: reference
            )
        }
    }
}

extension ServiceParameter: ComparableObject {

    var deltaIdentifier: DeltaIdentifier {
        .init(parameterName.value)
    }

    func compare(to other: ServiceParameter) -> ChangeContextNode {
        let context = ChangeContextNode()

        context.register(compare(\.parameterName, with: other), for: ParameterName.self)
        context.register(compare(\.necessity, with: other), for: Necessity.self)
        context.register(compare(\.type, with: other), for: ParameterType.self)
        context.register(compare(\.nilIsValidValue, with: other), for: NilIsValidValue.self)
        context.register(compare(\.schemaReference, with: other), for: SchemaReference.self)

        return context
    }

    func evaluate(result: ChangeContextNode, embeddedInCollection: Bool) -> Change? {
        let context: ChangeContextNode
        if !embeddedInCollection {
            guard let ownContext = result.change(for: Self.self) else { return nil }
            context = ownContext
        } else {
            context = result
        }

        let changes = [
            parameterName.change(in: context),
            necessity.change(in: context),
            type.change(in: context),
            nilIsValidValue.change(in: context),
            schemaReference.change(in: context)
        ].compactMap { $0 }

        guard !changes.isEmpty else { return nil }

        return .compositeChange(location: Self.changeLocation, changes: changes)
    }
}
