//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import TypeInformationMetadata


/// Types that can be returned from a `Handler`'s `handle` function should conform to `Content`.
/// `Content` includes the conformance to `Encodable`. If the types implement the `Encodable` requirements the type doesn't need to provide additional
/// implementation steps to conform to `ResponseTransformable`.
public protocol Content: Encodable & ResponseTransformable & StaticContentMetadataBlock {}

// MARK: Metadata DSL
public extension Content {
    /// Content Types have an empty `AnyContentMetadata` by default.
    static var metadata: any AnyContentMetadata {
        Empty()
    }
}
