//
//  ProtobufferExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 24.05.21.
//

import Foundation
import Apodini
import ApodiniGRPC

public struct ProtobufferExporterConfiguration {
    public var parentConfiguration: GRPCExporterConfiguration
    
    public init(parentConfiguration: GRPCExporterConfiguration = GRPCExporterConfiguration()) {
        self.parentConfiguration = parentConfiguration
    }
}
