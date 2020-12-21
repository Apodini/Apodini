//
 //  gRPCParameterOptions.swift
 //
 //
 //  Created by Moritz Schüll on 04.12.20.
 //

 import Foundation

 // MARK: gRPC specific `@Parameter` options

 /// A gRPC specific `PropertyOption` that allows the user to apply gRPC-specific options to a `@Parameter` property.
 public enum GRPCParameterOptions: PropertyOption {
     /// An explicit field-tag that should be used to decode the field from a Protobuffer encoded message
     case fieldTag(_ tag: Int)
 }

 extension PropertyOptionKey where PropertyNameSpace == ParameterOptionNameSpace, Option == GRPCParameterOptions {
     static let gRPC = PropertyOptionKey<ParameterOptionNameSpace, GRPCParameterOptions>()
 }

 extension AnyPropertyOption where PropertyNameSpace == ParameterOptionNameSpace {
     /// A gRPC specific `PropertyOption` that allows the user to apply gRPC-specific options to a `@Parameter` property.
     public static func gRPC(_ option: GRPCParameterOptions) -> AnyPropertyOption<ParameterOptionNameSpace> {
         AnyPropertyOption(key: .gRPC, value: option)
     }
 }
