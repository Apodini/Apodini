//
//  GRPCExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 24.05.21.
//

import Foundation
import Apodini

/// Configuration of the `GRPCInterfaceExporter`
public struct GRPCExporterConfiguration {
    /// The to be used `IntegerWidthConfiguration` of the `GRPCInterfaceExporter`
    public let integerWidth: IntegerWidthConfiguration
    
    /**
     Initializes the `GRPCExporterConfiguration`
     - Parameters:
     - integerWidth: The to be used `IntegerWidthConfiguration`, defaults to .native which automatically detects the systems setting
     */
    public init(integerWidth: IntegerWidthConfiguration = .native) {
        self.integerWidth = integerWidth

        guard integerWidth.rawValue <= Int.bitWidth else {
            preconditionFailure("\(self) requires architecture to have a wider integer bit width. Try using a smaller option.")
        }
    }
}
