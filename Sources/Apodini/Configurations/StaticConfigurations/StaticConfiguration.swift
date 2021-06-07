//
//  StaticConfiguration.swift
//  
//
//  Created by Philipp Zagar on 21.05.21.
//

/// `StaticConfiguration`s are used to register static services dependend on other services to Apodini.
public protocol StaticConfiguration {
    /**
     A method that handels the configuration of dependend static exporters
     - Parameters:
         - app: The `Vapor.Application` which is used to register the configuration in Apodini
         - parentConfiguration: The `Configuration` of the parent of the dependend exporter
     */
    func configure(_ app: Application, parentConfiguration: ExporterConfiguration)
}
