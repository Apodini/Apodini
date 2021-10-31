//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniNetworking

struct RESTPathBuilder: PathBuilder {
    private(set) var pathComponents: [HTTPPathComponent] = []
    private var pathString: [String] = []
    
    var pathDescription: String {
        pathString.joined(separator: "/")
    }

    mutating func append(_ string: String) {
        pathComponents.append(.verbatim(string))
        pathString.append(string)
    }

    mutating func root() {
        pathString.append("")
    }

    mutating func append<Type>(_ parameter: EndpointPathParameter<Type>) {
        pathComponents.append(.namedParameter(parameter.pathId))
        pathString.append("{\(parameter.name)}")
    }
}
