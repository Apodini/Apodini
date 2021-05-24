//
//  ProtobufferExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 24.05.21.
//

import Foundation
import Apodini

public class ProtobufferExporterConfiguration: TopLevelExporterConfiguration {
    var parentConfiguration: TopLevelExporterConfiguration
    
    public init(parentConfiguration: TopLevelExporterConfiguration = TopLevelExporterConfiguration()) {
        self.parentConfiguration = parentConfiguration
    }
}
