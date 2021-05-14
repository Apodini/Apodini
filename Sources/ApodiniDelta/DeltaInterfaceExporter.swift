//
//  DeltaInterfaceExporter.swift
//
//
//  Created by Eldi Cano on 14.05.21.
//

import Foundation
import Apodini
import ApodiniMigrator

public final class DeltaInterfaceExporter: StaticInterfaceExporter {
    public static var parameterNamespace: [ParameterNamespace] = .individual

    let app: Application

    public init(_ app: Application) {
        self.app = app
    }

    public func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
    }

    public func finishedExporting(_ webService: WebServiceModel) {
        
    }
}
