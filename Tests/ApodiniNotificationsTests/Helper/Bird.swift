//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

struct Bird: Codable {
    var name: String
    var age: Int
}

extension Bird {
    static func == (lhs: Bird, rhs: Bird) -> Bool {
        lhs.name == rhs.name && lhs.age == rhs.age
    }
}
