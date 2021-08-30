//
// Created by Andreas Bauer on 30.08.21.
//

import Apodini

public struct SummaryContextKey: OptionalContextKey {
    public typealias Value = String
}

public extension HandlerMetadataNamespace {
    typealias Summary = HandlerSummaryMetadata
}

public struct HandlerSummaryMetadata: HandlerMetadataDefinition {
    public typealias Key = SummaryContextKey

    public let value: String

    public init(_ summary: String) {
        self.value = summary
    }
}
