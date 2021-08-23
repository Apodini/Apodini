//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

#if DEBUG || RELEASE_TESTING
@testable import Apodini

// MARK: Guarded Handler
public extension Handler {
    /// Guards the handler with the given `guard`, just as `.guard()` does on `Component`s.
    /// - Note: This is only to be used when manually constructing an `Endpoint`
    func guarded<G: Guard>(_ guard: G) -> GuardingHandler<Self, G> {
        GuardingHandler(guarded: Delegate(self), guard: Delegate(`guard`))
    }
}
#endif
