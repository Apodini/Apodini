//
// Created by Andreas Bauer on 20.01.21.
//

/// Defines the identifying type passed to a `PathParameter`.
/// The identifying type is required to conform to `Identifiable`,
/// thus we save the `type` itself and its `Identifiable.ID` type.
/// Such definitions are e.g. used to match property resolvers of Relationship
/// definitions to their path parameter they actually resolve.
public struct IdentifyingType: PropertyOption, Equatable {
    /// The `Identifiable` type.
    public let type: Any.Type
    /// The `Identifiable.ID` type.
    public let idType: Any.Type

    init<Type: Identifiable>(identifying type: Type.Type = Type.self) {
        self.type = type
        self.idType = type.ID.self
    }

    public static func == (lhs: IdentifyingType, rhs: IdentifyingType) -> Bool {
        lhs.type == rhs.type && lhs.idType == rhs.idType
    }
}

extension PropertyOptionKey where PropertyNameSpace == ParameterOptionNameSpace, Option == IdentifyingType {
    static let identifying = PropertyOptionKey<ParameterOptionNameSpace, IdentifyingType>()
}

extension AnyPropertyOption where PropertyNameSpace == ParameterOptionNameSpace {
    /// A PathParameter specific option that indicates what Data type the `@PathParameter` is identifying
    static func identifying(_ identifyingType: IdentifyingType) -> AnyPropertyOption<ParameterOptionNameSpace> {
        AnyPropertyOption(key: .identifying, value: identifyingType)
    }
}
