//
//  WebSocketExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 26.05.21.
//

import Apodini

@available(macOS 12.0, *)
extension WebSocket {
    /// /// Configuration of the `WebSocketInterfaceExporter`
    public struct ExporterConfiguration {
        let path: String
        
        init(path: String = "apodini/websocket") {
            self.path = path
        }
    }
}
