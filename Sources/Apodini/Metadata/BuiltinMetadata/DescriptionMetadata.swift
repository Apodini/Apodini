//
// Created by Andreas Bauer on 17.05.21.
//

// TODO currently there is also the preexisting .description modifier
//  while this is fine, it is pretty tedious to implement (Handler)Modifier.
//  Therefore we should try to make some preexisting stuff facitiltating
//  the metadata infrastructure to easiyl add Handler/Componenet/(WebService) modifiers

public extension ComponentMetadataScope {
    typealias Description = ComponentDescriptionMetadata
}

public extension ContentMetadataScope {
    typealias Description = ContentDescriptionMetadata
}


public struct ComponentDescriptionMetadata: ComponentMetadata {
    public typealias Key = DescriptionContextKey

    public let value: String

    public init(_ description: String) {
        self.value = description
    }
}

// TODO currently its own thing, as Content Metadata is added to the same context as the Handler
public struct ContentDescriptionContextKey: OptionalContextKey {
    public typealias Value = String
}

public struct ContentDescriptionMetadata: ContentMetadata {
    public typealias Key = ContentDescriptionContextKey

    public let value: String

    public init(_ description: String) {
        self.value = description
    }
}
