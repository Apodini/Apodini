//
//  DeltaInterfaceExporter.swift
//  
//
//  Created by Eldi Cano on 19.03.21.
//

import Apodini

public final class DeltaInterfaceExporter: StaticInterfaceExporter {

    public static var parameterNamespace: [ParameterNamespace] = .individual

    let app: Application
    var endpoints: [AnyEndpoint] = []

    public init(_ app: Application) {
        self.app = app
    }

    public func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
        endpoints.append(endpoint)
    }

    public func finishedExporting(_ webService: WebServiceModel) {

    }

}
