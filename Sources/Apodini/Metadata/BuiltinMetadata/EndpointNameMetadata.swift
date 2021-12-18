//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniContext


extension HandlerMetadataNamespace {
    public typealias EndpointName = EndpointNameMetadata
}


public struct EndpointNameMetadata: HandlerMetadataDefinition {
    public struct Key: OptionalContextKey {
        public typealias Value = String
    }
    public let value: String

    public init(_ name: String) {
        self.value = name
    }
}

extension Handler {
    public func endpointName(_ name: String) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: EndpointNameMetadata(name))
    }
}





// TODO move this somewhere else

extension Endpoint {
    public enum EndpointNameFormat {
        case verbatim
        case camelCase
        case PascalCase
    }
    public func getEndointName(format: EndpointNameFormat) -> String? {
        guard let name = self[Context.self].get(valueFor: EndpointNameMetadata.Key.self) else {
            return nil
        }
        switch format {
        case .verbatim:
            return name
        case .camelCase:
            return name
        case .PascalCase:
            return name.capitalisingFirstCharacter
        }
    }
}
