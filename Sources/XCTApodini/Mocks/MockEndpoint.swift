//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

#if DEBUG || RELEASE_TESTING
@testable import Apodini
import struct Foundation.UUID

// MARK: Mock Endpoint
public extension Handler {
    /// Creates a basic Endpoint Model from the `Handler`.
    /// If `Application` is defined, it will be injected into all `ApplicationInjectables`.
    /// - Note: This endpoint's identifier is not guaranteed to be stable
    func mockEndpoint(
        app: Application? = nil,
        context: Context? = nil
    ) -> Endpoint<Self> {
        mockRelationshipEndpoint(app: app, context: context).0
    }
    
    /// Creates a basic Endpoint Model from the `Handler`.
    /// If `Application` is defined, it will be injected into all `ApplicationInjectables`.
    /// - Note: This endpoint's identifier is not guaranteed to be stable
    func mockRelationshipEndpoint(
        app: Application? = nil,
        context: Context? = nil
    ) -> (Endpoint<Self>, RelationshipEndpoint<Self>) {
        let context = context ?? Context()
        var handler = self
        if let application = app {
            handler = handler.inject(app: application)
        }
        
        var blackboard: Blackboard
        if let application = app {
            blackboard = LocalBlackboard<LazyHashmapBlackboard, GlobalBlackboard<LazyHashmapBlackboard>>(
                GlobalBlackboard<LazyHashmapBlackboard>(application),
                using: handler,
                context)
        } else {
            blackboard = LocalBlackboard<LazyHashmapBlackboard, LazyHashmapBlackboard>(LazyHashmapBlackboard(), using: handler, context)
        }

        return (Endpoint(
            handler: handler,
            blackboard: blackboard
        ), RelationshipEndpoint(
            handler: handler,
            blackboard: blackboard
        ))
    }
}
#endif
