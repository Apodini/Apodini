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
    public let parameters: [UUID: AnyEndpointParameter]
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self.parameters = blackboard[EndpointParameters.self].reduce(into: [UUID: AnyEndpointParameter](), { storage, parameter in
            storage[parameter.id] = parameter
        })
    }
}
