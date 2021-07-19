//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini

 // MARK: gRPC specific `@Parameter` options

 /// A gRPC specific `PropertyOption` that allows the user to apply gRPC-specific options to a `@Parameter` property.
 public enum GRPCParameterOptions: PropertyOption {
     /// An explicit field-tag that should be used to decode the field from a Protobuffer encoded message
     case fieldTag(_ tag: Int)
 }

 extension PropertyOptionKey where PropertyNameSpace == ParameterOptionNameSpace, Option == GRPCParameterOptions {
    /// A gRPC specific `PropertyOptionKey`.
    public static let gRPC = PropertyOptionKey<ParameterOptionNameSpace, GRPCParameterOptions>()
 }

 extension AnyPropertyOption where PropertyNameSpace == ParameterOptionNameSpace {
     /// A gRPC specific `PropertyOption` that allows the user to apply gRPC-specific options to a `@Parameter` property.
     public static func gRPC(_ option: GRPCParameterOptions) -> AnyPropertyOption<ParameterOptionNameSpace> {
         AnyPropertyOption(key: .gRPC, value: option)
     }
 }
