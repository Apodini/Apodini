//
//  Created by Andreas Bauer on 17.05.21.
//

public struct ParameterDescriptionContextKey: OptionalContextKey {
    public typealias Value = String
}

public extension ComponentMetadataNamespace {
    typealias ParameterDescription = ParameterDescriptionMetadata
}

public extension ComponentMetadataNamespace {
    typealias ParameterDescriptions = RestrictedComponentMetadataGroup<ParameterDescriptionMetadata>
}

public struct ParameterDescriptionMetadata: ComponentMetadataDefinition {
    public typealias Key = ParameterDescriptionContextKey

    public let value: String

    public init(_ description: String) {
        self.value = description
    }
}
