import Apodini
import Vapor

// NOTE DO NOT USE ANY OF THIS

private struct VaporApplicationLifecycleHandler: Apodini.LifecycleHandler {
    unowned let vaporApp: Vapor.Application
    
    func didBoot(_ application: Apodini.Application) throws {
        fatalError()
        // TODO?
        try vaporApp.boot() // TODO or start? or run?
    }
    
    func shutdown(_ application: Apodini.Application) throws {
        // TODO?
        vaporApp.shutdown()
    }
}


extension Apodini.Application {
    struct VaporAppStorageKey: Apodini.StorageKey {
        typealias Value = Vapor.Application
    }
    
    public var lk_vapor: Vapor.Application {
        if let vaporApp = self.storage[VaporAppStorageKey.self] {
            return vaporApp
        } else {
            let vaporEnv: Vapor.Environment = .production // This is what ApodiniVaporSupport uses???
            let vaporApp = Vapor.Application(vaporEnv, .shared(self.eventLoopGroup))
            //vaporApp.server. TODO!
            self.storage[VaporAppStorageKey.self] = vaporApp // TODO does this introduce a retain cycle?
            self.lifecycle.use(VaporApplicationLifecycleHandler(vaporApp: vaporApp))
            vaporApp.responder.use { [unowned vaporApp] app in
                precondition(app === vaporApp)
                fatalError()
            }
            // TODO somehow register a custom router?
//            vaporApp.servers.use { _ in LKCustomVaporServer() }
            //vaporApp.get(<#T##path: PathComponent...##PathComponent#>, use: <#T##(Request) throws -> ResponseEncodable#>)
            return vaporApp
        }
    }
}



//class LKCustomVaporServer: Vapor.Server {
//    init() {}
//
//    var onShutdown: EventLoopFuture<Void>
//
//    func shutdown() {
//
//    }
//}
//
