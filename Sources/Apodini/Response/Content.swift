//
//  Content.swift
//  
//
//  Created by Paul Schmiedmayer on 1/11/21.
//

import Foundation


/// Types that can be returned from a `Handler`'s `handle` function should conform to `Content`.
/// `Content` includes the conformance to `Encodable`. If the types implement the `Encodable` requirements the type doesn't need to provide additional
/// implementation steps to conform to `ResponseTransformable`.
public protocol Content: Encodable & ResponseTransformable, ContentMetadataNamespace {
    typealias Metadata = AnyContentMetadata

    @ContentMetadataBuilder
    static var metadata: Metadata { get }
}

// MARK: Metadata DSL
public extension Content {
    /// Content Types have an empty `AnyContentMetadata` by default.
    static var metadata: AnyContentMetadata {
        Empty()
    }
}
