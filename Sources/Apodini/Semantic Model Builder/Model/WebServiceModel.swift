//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation

public struct WebServiceModel: Blackboard {
    private let blackboard: Blackboard
    
    internal init(blackboard: Blackboard) {
        self.blackboard = blackboard
    }
    
    public subscript<S>(_ type: S.Type) -> S where S: KnowledgeSource {
        get {
            blackboard[type]
        }
        nonmutating set {
            blackboard[type] = newValue
        }
    }
    
    public func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource {
        try blackboard.request(type)
    }
}
