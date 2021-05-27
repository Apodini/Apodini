//
//  WebSocketExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 26.05.21.
//

import Apodini
import NIOWebSocket

public struct WebSocketExporterConfiguration: ExporterConfiguration {
    let path: String
    
    public init(path: String = "apodini/websocket") {
        self.path = path
    }
}
