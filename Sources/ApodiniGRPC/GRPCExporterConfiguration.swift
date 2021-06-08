//
//  GRPCExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 24.05.21.
//

import Foundation
import Apodini

public struct GRPCExporterConfiguration {
    public let integerWidth: IntegerWidthConfiguration
    
    public init(integerWidth: IntegerWidthConfiguration = .native) {
        self.integerWidth = integerWidth

        guard integerWidth.rawValue <= Int.bitWidth else {
            preconditionFailure("\(self) requires architecture to have a wider integer bit width. Try using a smaller option.")
        }
    }
}
