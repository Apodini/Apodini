//
//  File.swift
//  
//
//  Created by Alexander Collins on 19.11.20.
//

import Foundation



public struct EmptyConfiguration: Configuration {
    
    public init() {}
    
    public func handle() {}
}


extension EmptyConfiguration: Visitable {
    func visit(_ visitor: SynaxTreeVisitor) {}
}

extension Configuration {
    public var configure: Configuration { EmptyConfiguration() }
}

extension Configuration {
    public func handle() { }
}
