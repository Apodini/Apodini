import Foundation
import Apodini
import ApodiniHTTP
import ApodiniREST
import ApodiniGRPC



class Timer: Apodini.ObservableObject {
    //@Apodini.Published private var _trigger = true
    
    let interval: TimeInterval
    private var timer: Foundation.Timer?
    
    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    func start() {
        guard timer == nil else {
            return
        }
        timer?.invalidate()
        timer = .scheduledTimer(withTimeInterval: 1, repeats: true) { [unowned self] _ in
            print("AAAAAAAAAAAAAAAAAAA")
            //self._trigger.toggle()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}



struct Rocket: Handler {
    @Parameter(.mutability(.constant)) var start: Int = 10
    @State var counter = -1
//    @ObservedObject var timer = Timer(interval: 1)
    
    func handle() -> Apodini.Response<String> {
//        timer.start()
        counter += 1
        if counter == start {
//            timer.stop()
            return .final("🚀🚀🚀 Launch !!! 🚀🚀🚀")
        } else {
            return .send("\(start - counter)...")
        }
    }
    
    var metadata: AnyHandlerMetadata {
        Pattern(.serviceSideStream)
    }
}



struct WebService: Apodini.WebService {
    var content: some Component {
        Rocket()
    }
    
    var configuration: Configuration {
        HTTPConfiguration(
            hostname: .init(address: "localhost", port: 50001),
            bindAddress: .init(address: "localhost", port: 50001),
            tlsConfiguration: try! .makeServerConfiguration(
                certificatePath: "/Users/lukas/Documents/uni/apodini certs/localhost.cer.pem",
                keyPath: "/Users/lukas/Documents/uni/apodini certs/localhost.key.pem"
            )
        )
        GRPC(packageName: "de.lukaskollmer", serviceName: "LKTestWebService")
        HTTP()
    }
}


WebService.main()
