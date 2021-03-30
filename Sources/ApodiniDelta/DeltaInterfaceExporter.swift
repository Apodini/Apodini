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
        guard
            let configuration = app.storage.get(DeltaStorageKey.self)?.configuration,
            let webServiceStructuresPath = configuration.webServiceStructurePath
        else {
            fatalError("""
                No path specified for saving the web service structure. Use 'DeltaConfiguration' to specify where
                the web service structures should be saved.
                """)
        }

        switch configuration.strategy {
        case .create:
            webServiceStructure.export(at: webServiceStructuresPath)
            serveWebServiceStructure()
        case .compare:
            compare(path: webServiceStructuresPath)
        }
    }

    // currently mocked with the presaved file
    func compare(path: String) {
        do {
            let fileName = path + "web_service_v1.json"
            let data = try Data(contentsOf: URL(fileURLWithPath: fileName))
            let savedStructure = try JSONDecoder().decode(WebServiceStructure.self, from: data)

            let result = savedStructure.compare(to: webServiceStructure)
            if let change = webServiceStructure.evaluate(result: result, embeddedInCollection: false) {
                let jsonString = try change.jsonString()
                let jsonFileURL = URL(fileURLWithPath: path).appendingPathComponent("change.json")
                try jsonString.write(to: jsonFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print(error)
        }
    }

    func serveWebServiceStructure() {
        if let json = try? webServiceStructure.jsonString() {
            app.vapor.app.get("delta") { _ -> String in
                json
            }
        }
    }
}
