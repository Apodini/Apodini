//
//  WebSocketExporterConfiguration.swift
//  
//
//  Created by Philipp Zagar on 26.05.21.
//

import Apodini

struct WebSocketExporterConfiguration {
    let path: String
    
    init(path: String = "apodini/websocket") {
        self.path = path
    }
}
