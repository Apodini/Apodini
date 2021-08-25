//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem


struct AnyHandlerMetadataArray: AnyMetadataArray, AnyHandlerMetadata {
    let array: [AnyHandlerMetadata]

    init(_ array: [AnyHandlerMetadata]) {
        self.array = array
    }
}

struct AnyComponentOnlyMetadataArray: AnyMetadataArray, AnyComponentOnlyMetadata {
    let array: [AnyComponentOnlyMetadata]

    init(_ array: [AnyComponentOnlyMetadata]) {
        self.array = array
    }
}

struct AnyWebServiceMetadataArray: AnyMetadataArray, AnyWebServiceMetadata {
    let array: [AnyWebServiceMetadata]

    init(_ array: [AnyWebServiceMetadata]) {
        self.array = array
    }
}

struct AnyComponentMetadataArray: AnyMetadataArray, AnyComponentMetadata {
    let array: [AnyComponentMetadata]

    init(_ array: [AnyComponentMetadata]) {
        self.array = array
    }
}

struct AnyContentMetadataArray: AnyMetadataArray, AnyContentMetadata {
    let array: [AnyContentMetadata]

    init(_ array: [AnyContentMetadata]) {
        self.array = array
    }
}
