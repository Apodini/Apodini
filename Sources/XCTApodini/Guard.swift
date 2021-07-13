//
//  Guard.swift
//  
//
//  Created by Max Obermeier on 06.06.21.
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
