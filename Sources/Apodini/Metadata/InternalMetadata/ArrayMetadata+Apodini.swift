//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem


struct AnyHandlerMetadataArray: AnyMetadataArray, AnyHandlerMetadata {
    let array: [any AnyHandlerMetadata]

    init(_ array: [any AnyHandlerMetadata]) {
        self.array = array
    }
}

struct AnyComponentOnlyMetadataArray: AnyMetadataArray, AnyComponentOnlyMetadata {
    let array: [any AnyComponentOnlyMetadata]

    init(_ array: [any AnyComponentOnlyMetadata]) {
        self.array = array
    }
}

struct AnyWebServiceMetadataArray: AnyMetadataArray, AnyWebServiceMetadata {
    let array: [any AnyWebServiceMetadata]

    init(_ array: [any AnyWebServiceMetadata]) {
        self.array = array
    }
}

struct AnyComponentMetadataArray: AnyMetadataArray, AnyComponentMetadata {
    let array: [any AnyComponentMetadata]

    init(_ array: [any AnyComponentMetadata]) {
        self.array = array
    }
}
