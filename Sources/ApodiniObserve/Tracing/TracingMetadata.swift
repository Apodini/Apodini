//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

// TODO: Maybe non-optional with default of true
public struct TracingContextKey: OptionalContextKey {
    public typealias Value = Bool
}

extension ComponentMetadataNamespace {
    public typealias Tracing = TracingMetadata
}

public struct TracingMetadata: ComponentMetadataDefinition, DefinitionWithDelegatingHandler {
    public typealias Key = TracingContextKey

    public var value: Bool

    public let initializer: DelegatingHandlerContextKey.Value = [.init(TracingHandlerInitializer())]

    public init(isEnabled: Bool) {
        self.value = isEnabled
    }
}

extension Component {
    public func trace(isEnabled: Bool = true) -> ComponentMetadataModifier<Self> {
        self.metadata(TracingMetadata(isEnabled: true))
    }
}
