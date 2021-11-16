//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini


private struct HTTPServerStorageKey: StorageKey {
    typealias Value = HTTPServer
}


extension Application {
    struct HTTPServerLifecycleHandler: Apodini.LifecycleHandler {
        let httpServer: HTTPServer
        
        func didBoot(_ application: Application) throws {
            try httpServer.start()
        }
        
        func shutdown(_ application: Application) throws {
            try httpServer.shutdown()
        }
    }
    
    /// The application's underlying HTTP server.
    public var httpServer: HTTPServer {
        if let server = self.storage[HTTPServerStorageKey.self] {
            return server
        } else {
            let server = HTTPServer(
                app: self
            )
            self.lifecycle.use(HTTPServerLifecycleHandler(httpServer: server))
            self.storage[HTTPServerStorageKey.self] = server
            return server
        }
    }
}
