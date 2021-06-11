//
//  ProtobufferExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 24.05.21.
//

import Foundation
import Apodini
import ApodiniGRPC

extension Protobuffer {
    struct ExporterConfiguration {
        var parentConfiguration: GRPC.ExporterConfiguration
        
        init(parentConfiguration: GRPC.ExporterConfiguration = GRPC.ExporterConfiguration()) {
            self.parentConfiguration = parentConfiguration
        }
    }
}
