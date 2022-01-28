//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini


/// Handler metadata for explicitly defininga handler's input proto message typename, if necessary.
public struct HandlerInputProtoMessageName: HandlerMetadataDefinition {
    public struct Key: OptionalContextKey {
        public typealias Value = String
    }
    public let value: String
    
    public init(_ name: String) {
        self.value = name
    }
}


/// Handler metadata for explicitly defininga handler's response proto message typename, if necessary.
public struct HandlerResponseProtoMessageName: HandlerMetadataDefinition {
    public struct Key: OptionalContextKey {
        public typealias Value = String
    }
    public let value: String
    
    public init(_ name: String) {
        self.value = name
    }
}
