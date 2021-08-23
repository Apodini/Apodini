//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

public protocol AnyMetadataArrayWrapper: AnyMetadataBlock {}

public extension AnyMetadataArrayWrapper {
    /// Returns the type erased metadata content of the ``AnyMetadataBlock``.
    var blockContent: AnyMetadata {
        self
    }
}


struct AnyHandlerMetadataArrayWrapper: AnyMetadataArrayWrapper, AnyHandlerMetadata {
    let array: [AnyHandlerMetadata]

    init(_ array: [AnyHandlerMetadata]) {
        self.array = array
    }

    func collectMetadata(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.collectMetadata(visitor)
        }
    }
}

struct AnyComponentOnlyMetadataArrayWrapper: AnyMetadataArrayWrapper, AnyComponentOnlyMetadata {
    let array: [AnyComponentOnlyMetadata]

    init(_ array: [AnyComponentOnlyMetadata]) {
        self.array = array
    }

    func collectMetadata(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.collectMetadata(visitor)
        }
    }
}

struct AnyWebServiceMetadataArrayWrapper: AnyMetadataArrayWrapper, AnyWebServiceMetadata {
    let array: [AnyWebServiceMetadata]

    init(_ array: [AnyWebServiceMetadata]) {
        self.array = array
    }

    func collectMetadata(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.collectMetadata(visitor)
        }
    }
}

struct AnyComponentMetadataArrayWrapper: AnyMetadataArrayWrapper, AnyComponentMetadata {
    let array: [AnyComponentMetadata]

    init(_ array: [AnyComponentMetadata]) {
        self.array = array
    }

    func collectMetadata(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.collectMetadata(visitor)
        }
    }
}

struct AnyContentMetadataArrayWrapper: AnyMetadataArrayWrapper, AnyContentMetadata {
    let array: [AnyContentMetadata]

    init(_ array: [AnyContentMetadata]) {
        self.array = array
    }

    func collectMetadata(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.collectMetadata(visitor)
        }
    }
}
