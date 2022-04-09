//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Logging
import Tracing

extension Logger.MetadataValue {
    /// Transform this `MetadataValue` to `Tracing`.`SpanAttributes`, namespaced under the specified key.
    func spanAttributes(key: String) -> SpanAttributes {
        switch self {
        case let .string(value):
            return SpanAttributes([key: .string(value)])
        case let .stringConvertible(value):
            return SpanAttributes([key: .stringConvertible(value)])
        case let .dictionary(value): // value is [String: MetadataValue]
            return value
                .mapIntoDict { dictKey, dictValue -> (String, SpanAttributes) in
                    let nestedKey = "\(key).\(dictKey)"
                    return (nestedKey, dictValue.spanAttributes(key: nestedKey))
                }
                .reduce(into: SpanAttributes([:])) { attributes, entry in
                    attributes.merge(entry.value)
                }
        case let .array(value): // value is [MetadataValue]
            return value
                .enumerated()
                .mapIntoDict { index, arrayValue -> (String, SpanAttributes) in
                    let nestedKey = "\(key).\(index)"
                    return (nestedKey, arrayValue.spanAttributes(key: nestedKey))
                }
                .reduce(into: SpanAttributes([:])) { attributes, entry in
                    attributes.merge(entry.value)
                }
        }
    }
}
