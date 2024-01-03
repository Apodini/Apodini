//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import Foundation


public struct EndpointParametersById: KnowledgeSource {
    public let parameters: [UUID: any AnyEndpointParameter]
    
    public init<B>(_ sharedRepository: B) throws where B: SharedRepository {
        self.parameters = sharedRepository[EndpointParameters.self].reduce(into: [UUID: any AnyEndpointParameter](), { storage, parameter in
            storage[parameter.id] = parameter
        })
    }
}
