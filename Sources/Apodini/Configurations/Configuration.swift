//
//  Configuration.swift
//  
//
//  Created by Alexander Collins on 18.11.20.
//


public protocol Configuration {
    
    @ConfigurationBuilder var configure: Configuration { get }
    
    func handle() -> ()
}


extension Configuration {
    func visit(_ visitor: SynaxTreeVisitor) {
//        (visitor)
    }
}


extension SynaxTreeVisitor {
    func register<C: Configuration>(configuration: C) {
    }
}

public protocol ConfigurationCollection: Configuration {
    
}


extension ConfigurationCollection {
    func visitMe(_ visitor: SynaxTreeVisitor) {
        
    }
}
