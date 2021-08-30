//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

public struct ParameterDescriptionContextKey: ContextKey {
    public typealias Value = [UUID: String]
    public static var defaultValue: [UUID: String] = [:]

    public static func reduce(value: inout Value, nextValue: Value) {
        value.merge(nextValue) { _, new in
            new
        }
    }
}

public extension TypedComponentMetadataNamespace {
    typealias ParameterDescription = ParameterDescriptionMetadata<Self>
}

public extension ComponentMetadataNamespace {
    typealias ParameterDescription<Element: Component> = ParameterDescriptionMetadata<Element>
}

public struct ParameterDescriptionMetadata<Element: Component>: ComponentMetadataDefinition {
    public typealias Key = ParameterDescriptionContextKey
    public let value: ParameterDescriptionContextKey.Value

    public init<Value>(for parameter: Binding<Value>, _ description: String) {
        guard let id = _Internal.getParameterId(ofBinding: parameter) else {
            preconditionFailure("Parameter Description can only be constructed from a Binding of a @Parameter!")
        }
        self.value = [
            id: description
        ]
    }
}
