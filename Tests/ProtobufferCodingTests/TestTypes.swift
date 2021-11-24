//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import ProtobufferCoding
import Foundation


struct GenericSingleFieldMessage<T: Codable & Equatable>: Codable, Equatable {
    let value: T
}


struct SimpleDate: Codable {
    let year: Int
    let month: Int
    let day: Int
}


struct Person: Codable {
    let name: String
    let bday: SimpleDate
}
