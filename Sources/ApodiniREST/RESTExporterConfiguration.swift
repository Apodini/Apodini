//
//  RESTExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 21.05.21.
//

import Foundation
import Apodini
import ApodiniUtils

public class RESTExporterConfiguration: EncoderExporterConfiguration {
    public override init(encoder: AnyEncoder = JSONEncoder(), decoder: AnyDecoder = JSONDecoder()) {
        super.init(encoder: encoder, decoder: decoder)
    }
}
