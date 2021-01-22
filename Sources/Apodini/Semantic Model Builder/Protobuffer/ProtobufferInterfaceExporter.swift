//
//  Created by Nityananda on 03.12.20.
//

@_implementationOnly import class Vapor.Application

class ProtobufferInterfaceExporter: StaticInterfaceExporter {
    private let app: Application
    private let builder: ProtobufferBuilder
    
    required init(_ app: Application) {
        self.app = app
        self.builder = ProtobufferBuilder()
    }
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        do {
            try builder.analyze(endpoint: endpoint)
        } catch {
            app.logger.error("\(error)")
        }
    }
    
    func finishedExporting(_ webService: WebServiceModel) {
        let description = builder.description
        
        app.vapor.app.get("apodini", "proto") { _ in
            description
        }
    }
}
