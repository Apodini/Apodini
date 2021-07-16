//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini

struct WebSocketPathBuilder: PathBuilderWithResult {
    private var path: [String] = []
    
    mutating func append(_ string: String) {
        path.append(string.lowercased())
    }

    mutating func append<Type>(_ parameter: EndpointPathParameter<Type>) {
        path.append(":\(parameter.name):")
    }

    func result() -> String {
        path.joined(separator: ".")
    }
}
