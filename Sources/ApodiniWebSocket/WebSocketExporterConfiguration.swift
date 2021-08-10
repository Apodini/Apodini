//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini

extension WebSocket {
    /// Configuration of the `WebSocketInterfaceExporter`
    public struct ExporterConfiguration {
        public static let exporterType: Any.Type = WebSocketInterfaceExporter.self
        let path: String
        
        init(path: String = "apodini/websocket") {
            self.path = path
        }
    }
    
    public struct ExporterType {
        public static let exporterType: Any.Type = WebSocketInterfaceExporter.self
    }
}
