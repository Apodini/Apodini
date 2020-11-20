//
//  Configurator.swift
//  
//
//  Created by Alexander Collins on 19.11.20.
//

import Vapor


public class Configurator {
    private(set) var app: Application
    
    
    init(_ app: Application) {
        self.app = app
    }
    
    
    func register<C: Configuration>(configuration: C) { }
}
