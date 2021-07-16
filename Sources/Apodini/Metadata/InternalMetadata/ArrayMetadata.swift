//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
struct AnyHandlerMetadataArrayWrapper: AnyMetadataBlock, AnyHandlerMetadata {
    let array: [AnyHandlerMetadata]

    init(_ array: [AnyHandlerMetadata]) {
        self.array = array
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.accept(visitor)
        }
    }
}

struct AnyComponentOnlyMetadataArrayWrapper: AnyMetadataBlock, AnyComponentOnlyMetadata {
    let array: [AnyComponentOnlyMetadata]

    init(_ array: [AnyComponentOnlyMetadata]) {
        self.array = array
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.accept(visitor)
        }
    }
}

struct AnyWebServiceMetadataArrayWrapper: AnyMetadataBlock, AnyWebServiceMetadata {
    let array: [AnyWebServiceMetadata]

    init(_ array: [AnyWebServiceMetadata]) {
        self.array = array
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.accept(visitor)
        }
    }
}

struct AnyComponentMetadataArrayWrapper: AnyMetadataBlock, AnyComponentMetadata {
    let array: [AnyComponentMetadata]

    init(_ array: [AnyComponentMetadata]) {
        self.array = array
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.accept(visitor)
        }
    }
}

struct AnyContentMetadataArrayWrapper: AnyMetadataBlock, AnyContentMetadata {
    let array: [AnyContentMetadata]

    init(_ array: [AnyContentMetadata]) {
        self.array = array
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.accept(visitor)
        }
    }
}
