//
//  Configurator.swift
//  
//
//  Created by Alexander Collins on 19.11.20.
//

import Vapor

protocol Configurable {
    func configurable(by configurator: Configurator)
}

public class Configurator {
    private(set) var app: Application
    private(set) var currentNode: ContextNode = ContextNode()
    
    init(_ app: Application) {
        self.app = app
    }
    
    
    func register<C: Configuration>(configuration: C) {
        let context = Context(contextNode: currentNode.copy())
        executeConfiguration(config: configuration, context: context)
        currentNode.resetContextNode()
    }
    
    private func executeConfiguration<C: Configuration>(config: C, context: Context) {
        let _ = config.configure(app)
    }
    
    func enter<C: ConfigurationCollection>(collection: C) {
        currentNode = currentNode.newContextNode()
    }
    
    func exit<C: ConfigurationCollection>(collection: C) {
        if let parentNode = currentNode.parentContextNode {
            currentNode = parentNode
        }
    }
}
