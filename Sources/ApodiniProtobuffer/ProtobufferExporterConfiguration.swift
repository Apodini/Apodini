//
//  ProtobufferExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 24.05.21.
//

import Foundation
import Apodini
import ApodiniGRPC

public struct ProtobufferExporterConfiguration: ExporterConfiguration {
    public var parentConfiguration: ExporterConfiguration
    
    public init(parentConfiguration: ExporterConfiguration = GRPCExporterConfiguration()) {
        self.parentConfiguration = parentConfiguration
    }
}
