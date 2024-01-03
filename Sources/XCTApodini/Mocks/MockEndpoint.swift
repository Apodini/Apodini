//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

#if DEBUG || RELEASE_TESTING
@testable import Apodini
@testable import ApodiniContext
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
        
        var sharedRepository: any SharedRepository
        if let application = app {
            sharedRepository = LocalSharedRepository<LazyHashmapSharedRepository, GlobalSharedRepository<LazyHashmapSharedRepository>>(
                GlobalSharedRepository<LazyHashmapSharedRepository>(application),
                using: handler,
                context)
        } else {
            sharedRepository = LocalSharedRepository<LazyHashmapSharedRepository, LazyHashmapSharedRepository>(
                LazyHashmapSharedRepository(),
                using: handler,
                context
            )
        }

        return (Endpoint(
            sharedRepository: sharedRepository
        ), RelationshipEndpoint(
            handler: handler,
            sharedRepository: sharedRepository
        ))
    }
}
#endif
