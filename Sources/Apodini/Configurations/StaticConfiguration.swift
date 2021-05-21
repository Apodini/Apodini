//
//  StaticConfiguration.swift
//  
//
//  Created by Philipp Zagar on 21.05.21.
//

import Foundation
import ApodiniUtils
import Vapor

public struct ParentConfiguration {
    let encoder: Vapor.ContentEncoder
    let decoder: Vapor.ContentDecoder
    
    public init(encoder: Vapor.ContentEncoder, decoder: Vapor.ContentDecoder) {
        self.encoder = encoder
        self.decoder = decoder
    }
}

public protocol StaticConfiguration {
    func configure(_ app: Application, _ parentConfiguration: ParentConfiguration)
}

public struct EmptyStaticConfiguration: StaticConfiguration {
    public func configure(_ app: Application, _ parentConfiguration: ParentConfiguration) { }
    
    public init() { }
}

extension Array where Element == StaticConfiguration {
    public func configure(_ app: Application, _ parentConfiguration: ParentConfiguration) {
        forEach {
            $0.configure(app, parentConfiguration)
        }
    }
}
