//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation
import Apodini


extension HandlerMetadataNamespace {
    /// Endpoint name
    public typealias EndpointName = EndpointNameMetadata
}


/// Endpoint name metadata input
public enum EndpointNameMetadataInput {
    /// A string which should be used as the basis for generating a good endpoint name
    case name(String)
    /// Hard-coded noun and verb variants. Custom formatting will still apply
    case noun(String, verb: String)
    /// Hardcoded name which should be used. No custom formatting will apply
    case verbatimName(String)
}


public struct EndpointNameMetadata: HandlerMetadataDefinition {
    public struct Key: OptionalContextKey {
        public typealias Value = EndpointNameMetadataInput
    }
    public let value: EndpointNameMetadataInput
    
    /// Create a new endpoint name from the specified input
    public init(_ value: EndpointNameMetadataInput) {
        self.value = value
    }
    
    /// Create a new endpoint name from the specified string
    public init(_ name: String) {
        self.init(.name(name))
    }
}


extension Handler {
    /// Define a custom endpoint name for this handler's resulting endpoint.
    public func endpointName(_ name: String) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: EndpointNameMetadata(.name(name)))
    }
    
    /// Define a custom endpoint name for this handler's resulting endpoint.
    public func endpointName(noun: String, verb: String) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: EndpointNameMetadata(.noun(noun, verb: verb)))
    }
    
    /// Define a custom endpoint name for this handler's resulting endpoint.
    public func endpointName(fixed name: String) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: EndpointNameMetadata(.verbatimName(name)))
    }
}


extension Endpoint {
    /// Endpoint name generation variant.
    public enum EndpointNamePartOfSpeech {
        /// The endpoint name should be returned as a noun (best effort)
        case noun
        /// The endpoint name should be returned as a verb (best effort)
        case verb
    }
    
    /// Formatting option for an endpoint name
    public enum EndpointNameFormat {
        /// No formatting should be applied to the endpoint name.
        case verbatim
        /// The endpoint name should be formatted using `camelCase`
        case camelCase
        /// The endpoint name should be formatted using `PascalCase`
        case pascalCase
        /// The endpoint name should be formatted using `snakeCase`
        case snakeCase
    }
    
    
    /// Attempts to generate an endpoint name suitable for e.g. method names in an exported API.
    /// - Note: This is a best-effort implementation, and there is no guarantee that the resulting name will make sense or even be unique within the web service.
    /// - parameter preferredOutputType: Whether the resulting name should be e.g. a noun or a verb
    /// - parameter format: How the resulting string should be formatted, e.g. using `camelCase`, `snake_case`, or others
    public func getEndointName( // swiftlint:disable:this cyclomatic_complexity
        _ preferredOutputType: EndpointNamePartOfSpeech,
        format outputFormat: EndpointNameFormat
    ) -> String {
        let nameInput: EndpointNameMetadataInput = self[Context.self].get(valueFor: EndpointNameMetadata.Key.self) ?? .name("\(H.self)")
        if case .verbatimName(let name) = nameInput {
            return name
        }
        let nameBase: String = {
            switch nameInput {
            case .name(let name):
                return name
            case let .noun(noun, verb):
                switch preferredOutputType {
                case .noun:
                    return noun
                case .verb:
                    return verb
                }
            case .verbatimName:
                fatalError("Should be unreachable")
            }
        }()
        func format(_ nameComponents: [String]) -> String {
            switch outputFormat {
            case .verbatim:
                return nameBase
            case .camelCase:
                return nameComponents.camelCase()
            case .pascalCase:
                return nameComponents.pascalCase()
            case .snakeCase:
                return nameComponents.snakeCase()
            }
        }
        let nameComponents = nameBase.splitIntoWords(delimiters: [.whitespace, .uppercase, .character("_")])
        guard !nameComponents.isEmpty else {
            // If the name can't be split into its components, there isn't much we can do...
            return nameBase
        }
        let operation = self[Operation.self]
        switch preferredOutputType {
        case .noun:
            if nameComponents.count > 1 && Self.wellKnownEndpointNameVerbPrefixes(for: operation).contains(nameComponents.first!.lowercased()) {
                return format(Array(nameComponents.dropFirst()))
            } else {
                return format(nameComponents)
            }
        case .verb:
            if Self.wellKnownEndpointNameVerbPrefixes(for: operation).contains(nameComponents.first!.lowercased()) {
                return format(nameComponents)
            } else {
                return format([Self.defaultEndpointNameVerbPrefix(for: operation)] + nameComponents)
            }
        }
    }
    
    
    private static func wellKnownEndpointNameVerbPrefixes(for operation: Apodini.Operation) -> Set<String> {
        switch operation {
        case .create:
            return ["create", "make", "new", "add"]
        case .read:
            return ["get", "list", "fetch", "query", "read"]
        case .update:
            return ["update"]
        case .delete:
            return ["delete", "remove"]
        }
    }
    
    private static func defaultEndpointNameVerbPrefix(for operation: Apodini.Operation) -> String {
        switch operation {
        case .create:
            return "create"
        case .read:
            return "get"
        case .update:
            return "update"
        case .delete:
            return "delete"
        }
    }
}
