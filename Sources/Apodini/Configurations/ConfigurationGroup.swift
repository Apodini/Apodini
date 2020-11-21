//
//  File.swift
//  
//
//  Created by Alexander Collins on 19.11.20.
//

import Foundation

public struct ConfigurationGroup<Content: Configuration>: ConfigurationCollection {
    public func configure() {
        print("grouphandle")
    }
    
    public let content: Content
    
    public init(@ConfigurationBuilder content: () -> Content) {
        self.content = content()
    }
}

extension ConfigurationGroup: Configurable {
    
    func configurable(by configurator: Configurator) {
        configurator.enter(collection: self)
        content.configurable(by: configurator)
        configurator.exit(collection: self)
    }
}
