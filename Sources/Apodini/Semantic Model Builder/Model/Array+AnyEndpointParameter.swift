//
//  File.swift
//  
//
//  Created by Nityananda on 07.01.21.
//

extension Array where Element == AnyEndpointParameter {
    func exportParameters<I: InterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput] {
        self.map { parameter -> I.ParameterExportOutput in
            parameter.exportParameter(on: exporter)
        }
    }
}
