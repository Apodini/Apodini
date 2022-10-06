//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


extension SyntaxTreeVisitor {
    enum UnsafeVisitAny: Swift.Error {
        /// The error thrown when attempting to unsafely visit a value which does not conform to the `Component` protocol.
        case attemptedToVisitNonComponentValue(Any, visitor: SyntaxTreeVisitor)
    }

    /// Allows you to visit an object that you know implements Component, even if you don't know the concrete type at compile time.
    func unsafeVisitAny(_ value: Any) throws {
        if let component = value as? any Component {
            component.accept(self)
        } else {
            throw UnsafeVisitAny.attemptedToVisitNonComponentValue(value, visitor: self)
        }
    }
}
