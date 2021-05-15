//
//  AnyCheckHandler.swift
//  
//
//  Created by Paul Schmiedmayer on 5/15/21.
//

#if DEBUG
import Apodini


public protocol AnyCheckHandler {
    func check(endpoints: [AnyEndpoint], app: Application, exporter mockExporter: MockExporter) throws
}
#endif
