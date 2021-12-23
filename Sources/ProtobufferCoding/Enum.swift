//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation


public protocol AnyProtobufEnum: __ProtoTypeWithReservedFields {
    static var allCases: [Self] { get }
    var rawValue: Int32 { get }
}


/// A Swift enum type which can be stored into protobuffer messages.
public protocol ProtobufEnum: AnyProtobufEnum, Codable, CaseIterable, RawRepresentable where RawValue == Int32 {}
