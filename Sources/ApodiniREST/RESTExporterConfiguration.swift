//
//  RESTExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 21.05.21.
//

import Foundation
import Apodini
import ApodiniUtils

public struct RESTExporterConfiguration: ExporterConfiguration {
    public let encoder: AnyEncoder
    public let decoder: AnyDecoder
    
    public init(encoder: @autoclosure () -> AnyEncoder = {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
                    return encoder }(),
                decoder: AnyDecoder = JSONDecoder()) {
        self.encoder = encoder()
        self.decoder = decoder
    }
    
    
}
