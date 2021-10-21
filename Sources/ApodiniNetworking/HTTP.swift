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
    
    public var httpServer: HTTPServer {
        if let server = self.storage[HTTPServerStorageKey.self] {
            return server
        } else {
            let server = HTTPServer(
                app: self // TODO does this introduce a retain cycle?
            )
            self.lifecycle.use(HTTPServerLifecycleHandler(httpServer: server))
            self.storage[HTTPServerStorageKey.self] = server
            return server
        }
    }
    
    
}
