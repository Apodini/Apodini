//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

public struct ResponseType: KnowledgeSource {
    public let type: Encodable.Type
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self.type = blackboard[HandleReturnType.self].type
    }
}
