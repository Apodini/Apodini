//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 11/3/20.
//

@_implementationOnly import Vapor
import NIO


class SemanticModelBuilder {
    private(set) var app: Application
    
    init(_ app: Application) {
        self.app = app
    }
    
    func register<C: Component>(component: C, withContext context: Context) {
        // Overwritten by subclasses of the SemanticModelBuilder
    }

    func finishedProcessing() {
        // Can be overwritten to run action once the component tree was parsed
    }
}
