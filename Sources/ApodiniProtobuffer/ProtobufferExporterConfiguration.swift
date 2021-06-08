//
//  ProtobufferExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 24.05.21.
//

import Foundation
import Apodini
import ApodiniGRPC

struct ProtobufferExporterConfiguration {
    var parentConfiguration: GRPCExporterConfiguration
    
    init(parentConfiguration: GRPCExporterConfiguration = GRPCExporterConfiguration()) {
        self.parentConfiguration = parentConfiguration
    }
}
