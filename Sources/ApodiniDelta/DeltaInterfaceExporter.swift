//
//  DeltaInterfaceExporter.swift
//  
//
//  Created by Eldi Cano on 19.03.21.
//

import Foundation
import Apodini
import ApodiniVaporSupport

public final class DeltaInterfaceExporter: StaticInterfaceExporter {

    public static var parameterNamespace: [ParameterNamespace] = .individual

    let app: Application
    var webServiceStructure = WebServiceStructure()

    public init(_ app: Application) {
        self.app = app
    }

    public func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
        webServiceStructure.addEndpoint(endpoint)
    }

    public func finishedExporting(_ webService: WebServiceModel) {
        serveWebServiceStructure()

        guard
            let webServiceStructuresPath = app.storage.get(DeltaStorageKey.self)?.configuration.webServiceStructurePath
        else {
            fatalError("""
                No path specified for saving the web service structure. Use 'DeltaConfiguration' to specify where
                the web service structures should be saved.
                """)
             }
        webServiceStructure.export(at: webServiceStructuresPath)
    }

    func serveWebServiceStructure() {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        if
            let data = try? jsonEncoder.encode(webServiceStructure),
            let jsonString = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\/", with: "/") {

            app.vapor.app.get("delta") { _ -> String in
                jsonString
            }
        }
    }

}
