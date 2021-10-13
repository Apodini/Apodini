//
//  Application+InterfaceExporter.swift
//  Application+InterfaceExporter
//
//  Created by Paul Schmiedmayer on 7/21/21.
//

@testable import Apodini
import ApodiniExtension
import XCTest


extension Application {
    private class AnyInterfaceExporterVisitor<I: InterfaceExporter>: InterfaceExporterVisitor {
        var interfaceExporter: I?
        
        
        func visit<VisitingInterfaceExporter: InterfaceExporter>(exporter: VisitingInterfaceExporter) {
            if let exporter = exporter as? I {
                interfaceExporter = exporter
            }
        }
    }
    
    public func getInterfaceExporter<I: InterfaceExporter>(_ type: I.Type = I.self) throws -> I {
        let visitor = AnyInterfaceExporterVisitor<I>()
        self.interfaceExporters.acceptAll(visitor)
        return try XCTUnwrap(visitor.interfaceExporter)
    }
}

