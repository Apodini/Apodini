//
//  File.swift
//  
//
//  Created by Alexander Collins on 19.11.20.
//

import Foundation

public struct ConfigurationGroup: ConfigurationCollection {
    public let configure: Configuration
    
    
    public init(@ConfigurationBuilder configure: () -> Configuration) {
        self.configure = configure()
    }
}


extension ConfigurationGroup: Visitable {
    func visit(_ visitor: SynaxTreeVisitor) {

    }
}
