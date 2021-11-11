//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini

extension GRPC {
    /// Configuration of the `GRPCInterfaceExporter`
    public struct ExporterConfiguration {
        /// The to be used `IntegerWidthConfiguration` of the `GRPCInterfaceExporter`
        public let integerWidth: IntegerWidthConfiguration
        
        /// Initializes the `GRPCExporterConfiguration`
        /// - Parameters:
        /// - integerWidth: The to be used `IntegerWidthConfiguration`, defaults to .native which automatically detects the systems setting
        public init(integerWidth: IntegerWidthConfiguration = .native) {
            self.integerWidth = integerWidth

            guard integerWidth.rawValue <= Int.bitWidth else {
                preconditionFailure("\(self) requires architecture to have a wider integer bit width. Try using a smaller option.")
            }
        }
    }
}
