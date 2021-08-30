//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

/// ContextKey which stores ``JSONSchemeModificationType`` declared on Content Metadata.
public struct OpenAPIJSONSchemeModificationContextKey: ContextKey {
    public typealias Value = [JSONSchemeModificationType]
    public static var defaultValue: [JSONSchemeModificationType] = []
}

// TODO remove?
public struct OpenAPIParameterSchemeModificationContextKey: ContextKey { // swiftlint:disable:this type_name
    public typealias Value = [UUID: [JSONSchemeModificationType]]
    public static var defaultValue: [UUID: [JSONSchemeModificationType]] = [:]

    public static func reduce(value: inout Value, nextValue: Value) {
        value.merge(nextValue) { current, new in
            current + new
        }
    }
}
