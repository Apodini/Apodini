//
//  Created by Andreas Bauer on 17.05.21.
//

public struct ParameterDescriptionContextKey: OptionalContextKey {
    public typealias Value = String
}

public extension ComponentMetadataScope {
    typealias ParameterDescription = ParameterDescriptionMetadata
}

public extension ComponentMetadataScope {
    typealias ParameterDescriptions = RestrictedComponentMetadataGroup<ParameterDescriptionMetadata>
}

public struct ParameterDescriptionMetadata: ComponentMetadataDeclaration {
    public typealias Key = ParameterDescriptionContextKey

    public let value: String

    public init(_ description: String) {
        self.value = description
    }
}
