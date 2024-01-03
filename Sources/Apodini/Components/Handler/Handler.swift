//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import NIO


/// A `Handler` is a `Component` which defines an endpoint and can handle requests.
public protocol Handler: AnyHandlerMetadataBlock, Component where MetadataBuilderScope == MetadataBuilderScope_Handler { // TODO we might also be able to express the Scope stuff as a `where Metadata: AnyHandlerMetadata` (as already suggested by the compiler for the other thing), and then somehow using this in the MetadataBuilder as well... (repurpose the generic parameter for a `where T: AnyHandlerMetadata` etc)
    /// The type that is returned from the `handle()` method when the component handles a request. The return type of the `handle` method is encoded into the response send out to the client.
    associatedtype Response: ResponseTransformable
    
    typealias Metadata = any AnyHandlerMetadata
    
    /// A function that is called when a request reaches the `Handler`
    func handle() async throws -> Response
}


// MARK: Metadata DSL
public extension Handler {
    /// Handlers have an empty `AnyHandlerMetadata` by default.
    var metadata: any AnyHandlerMetadata {
        Empty()
    }
}


extension Handler {
    /// By default, `Handler`s don't provide any further content
    public var content: some Component {
        EmptyComponent()
    }
}




extension Component where MetadataBuilderScope == MetadataBuilderScope_ComponentOnly {
    var SCOPE__COMPONENT_IS_COMPONENT: Never { fatalError() }
}


extension Component where MetadataBuilderScope == MetadataBuilderScope_Handler {
    var SCOPE__COMPONENT_IS_HANDLER: Never { fatalError() }
}

extension Handler where MetadataBuilderScope == MetadataBuilderScope_Handler {
    var SCOPE__HANDLER_IS_HANDLER: Never { fatalError() }
}
