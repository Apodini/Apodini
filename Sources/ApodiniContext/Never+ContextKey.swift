//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

extension Never: ContextKey, OptionalContextKey {
    public typealias Value = Never
    public static var defaultValue: Value {
        fatalError("The ContextKey default value cannot be accessed for ContextKey of type Never")
    }
}
