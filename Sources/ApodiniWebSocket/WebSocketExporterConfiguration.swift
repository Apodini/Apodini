//
//  WebSocketExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 26.05.21.
//

import Apodini

extension WebSocket {
    public struct ExporterConfiguration {
        let path: String
        
        init(path: String = "apodini/websocket") {
            self.path = path
        }
    }
}
