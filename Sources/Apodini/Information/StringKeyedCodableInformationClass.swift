//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//    

/// The ``InformationClass`` identifying any ``Information`` which holds Codable information.
public protocol StringKeyedCodableInformationClass: InformationClass {
    var entry: (key: String, value: Codable) { get }
}
