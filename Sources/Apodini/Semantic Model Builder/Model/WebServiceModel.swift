//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

public struct WebServiceModel: SharedRepository {
    private let sharedRepository: any SharedRepository
    
    internal init(sharedRepository: any SharedRepository) {
        self.sharedRepository = sharedRepository
    }
    
    public subscript<S>(_ type: S.Type) -> S where S: KnowledgeSource {
        get {
            sharedRepository[type]
        }
        nonmutating set {
            sharedRepository[type] = newValue
        }
    }
    
    public func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource {
        try sharedRepository.request(type)
    }
}
