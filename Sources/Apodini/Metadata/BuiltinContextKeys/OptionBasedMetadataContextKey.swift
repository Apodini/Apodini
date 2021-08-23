//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

public struct OptionBasedMetadataContextKey<Namespace>: OptionalContextKey {
    public typealias Value = PropertyOptionSet<Namespace>

    public static func reduce(value: inout PropertyOptionSet<Namespace>, nextValue: PropertyOptionSet<Namespace>) {
        value.merge(withRHS: nextValue)
    }
}
