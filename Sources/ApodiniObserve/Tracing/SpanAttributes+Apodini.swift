//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Tracing

extension SpanAttributes {
    public var apodini: ApodiniSpanAttributes {
        get { .init(attributes: self) }
        set { self = newValue.attributes }
    }
}

public struct ApodiniSpanAttributes: SpanAttributeNamespace {
    public var attributes: SpanAttributes

    public init(attributes: SpanAttributes) {
        self.attributes = attributes
    }

    public struct NestedSpanAttributes: NestedSpanAttributesProtocol {
        public init() {}

        public var endpointName: Key<String> {
            "apodini.endpoint.name"
        }

        public var endpointOperation: Key<String> {
            "apodini.endpoint.operation"
        }

        public var endpointPath: Key<String> {
            "apodini.endpoint.path"
        }

        public var endpointCommunicationalPattern: Key<String> {
            "apodini.endpoint.communicationalPattern"
        }

        public var endpointVersion: Key<String> {
            "apodini.endpoint.version"
        }
    }
}
