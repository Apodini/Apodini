import Apodini
import ApodiniHTTP
import ApodiniREST
import ApodiniGRPC
import Foundation






class FakeTimer: Apodini.ObservableObject {
    @Apodini.Published private var _trigger = true
    
    init() { }
    
    func secondPassed() {
        _trigger.toggle()
    }
    
    deinit {
        print(Self.self, #function)
    }
}



struct Rocket: Handler {
    @Parameter(.http(.query), .mutability(.constant)) var start: Int = 10
    
    @State var counter = -1
    
    @ObservedObject var timer = FakeTimer()
    
    func handle() -> Apodini.Response<String> {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 2) {
            print("tick")
            timer.secondPassed()
        }
        counter += 1
        
        if counter == start {
            print("Sending .final")
            //return .final(.init(.init(string: "🚀🚀🚀 Launch !!! 🚀🚀🚀\n"), type: .text(.plain, parameters: ["charset": "utf-8"])))
            return .final("🚀🚀🚀 Launch !!! 🚀🚀🚀\n")
        } else {
            print("Sending .send(\(start - counter))")
            return .send("\(start - counter)...\n")
            //return .send(.init(.init(string: "\(start - counter)...\n"), type: .text(.plain, parameters: ["charset": "utf-8"])))
        }
    }
    
    
    var metadata: AnyHandlerMetadata {
        Pattern(.serviceSideStream)
    }
}



struct RocketBlob: Handler {
    @Parameter(.http(.query), .mutability(.constant)) var start: Int = 10
    
    @State var counter = -1
    
    @ObservedObject var timer = FakeTimer()
    
    func handle() -> Apodini.Response<Blob> {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 2) {
            print("tick")
            timer.secondPassed()
        }
        counter += 1
        
        if counter == start {
            print("Sending .final")
            return .final(.init(.init(string: "🚀🚀🚀 Launch !!! 🚀🚀🚀\n"), type: .text(.plain, parameters: ["charset": "utf-8"])))
            //return .final("🚀🚀🚀 Launch !!! 🚀🚀🚀\n".data(using: .utf8)!)
        } else {
            print("Sending .send(\(start - counter))")
            //return .send("\(start - counter)...\n".data(using: .utf8)!)
            return .send(.init(.init(string: "\(start - counter)...\n"), type: .text(.plain, parameters: ["charset": "utf-8"])))
        }
    }
    
    
    var metadata: AnyHandlerMetadata {
        Pattern(.serviceSideStream)
    }
}






struct Person: Codable {
    struct LKDate: Codable {
        let year: Int
        let month: Int
        let day: Int
    }
    
    let name: String
    let dateOfBirth: LKDate
    
    enum CodingKeys: Int, CodingKey {
        case name = 1
        case dateOfBirth = 2
    }
}


struct DateParsingError: Error {
    let message: String
}


struct Greeter2: Handler {
    @Parameter var person: Person
    
    func handle() async throws -> some ResponseTransformable {
        guard let date = Calendar.current.date(from: DateComponents(
            year: person.dateOfBirth.year,
            month: person.dateOfBirth.month,
            day: person.dateOfBirth.day
        )) else {
            throw DateParsingError(message: "Invalid input: \(person.dateOfBirth)")
        }
        let cal = Calendar.current
        let diff = cal.dateComponents([.year], from: date, to: Date())
        return "Hello, \(person.name). You were born \(diff.year!) years ago!"
    }
}

struct Greeter: Handler {
    @Parameter(.http(.path)) var name: String
    
    func handle() async throws -> some ResponseTransformable {
        return "Hello, \(name)!"
    }
}


struct StreamingGreeter_CS: Handler {
    @Environment(\.connection) var connection
    @Parameter var name: String
    @State private var names: [String] = []
    
    func handle() async throws -> Response<String> {
        print("GREETER. name: \(name), names: \(names), connection: \(connection) (state: \(connection.state))")
        if self.connection.state == .end {
            switch names.count {
            case 0:
                return .final("Hello!")
            case 1:
                return .final("Hello, \(names[0])")
            default:
                return .final("Hello, \(names[0..<(names.endIndex - 1)].joined(separator: ", ")), and \(names.last!)")
            }
        } else {
            names.append(name)
            return .send()
            //return .nothing
        }
    }
}

struct StreamingGreeter_BS: Handler {
    @Parameter var name: String
    
    func handle() async throws -> Response<String> {
        print("GREET \(name.uppercased())")
        return .send("Hello, \(name)!")
    }
}


struct ThrowingHandler: Handler {
    private struct Error: Swift.Error {
        let message: String
    }
    
    //func handle() async throws -> some ResponseTransformable {
    func handle() async throws -> Never {
        throw Error(message: "oh no")
    }
}


struct LKTestWebService: Apodini.WebService {
    var content: some Component {
        Text("Hello World!")
            .gRPCMethodName("root")
        Group("greet") {
            Greeter()
                .gRPCMethodName("greet")
        }
        Group("greet2") {
            Greeter2()
                .gRPCMethodName("greet2")
        }
        Group("greet_cs") {
            StreamingGreeter_CS()
                .gRPCMethodName("greet_cs")
                .pattern(.clientSideStream)
        }
        Group("greet_bs") {
            StreamingGreeter_BS()
                .gRPCMethodName("greet_bs")
                .pattern(.bidirectionalStream)
        }
        Group("rocket") {
            Rocket()
                .gRPCMethodName("rocket")
        }
        Group("rocketBlob") {
            RocketBlob()
                .gRPCMethodName("rocketBlob")
        }
        Group("throw") {
            ThrowingHandler()
                .gRPCMethodName("throw")
        }
    }
    
    var configuration: Configuration {
        HTTPConfiguration(
            //hostname: .init(address: "localhost", port: 50001),
            bindAddress: .interface("localhost", port: 50001),
            tlsConfigurationBuilder: TLSConfigurationBuilder(
                certificatePath: "/Users/lukas/Documents/apodini certs/localhost.cer.pem",
                keyPath: "/Users/lukas/Documents/apodini certs/localhost.key.pem"
            )
        )
//        HTTP2Configuration(
//            cert: "/Users/lukas/Documents/apodini certs/localhost.cer.pem",
//            keyPath: "/Users/lukas/Documents/apodini certs/localhost.key.pem"
//        )
//        ApodiniHTTP.HTTP()
        //HTTP2Configuration(cert: <#T##String?#>, keyPath: <#T##String?#>)
        //HTTPConfiguration(hostname: "localhost")
//        REST()
        GRPC(packageName: "de.lukaskollmer", serviceName: "TestWebService")
//        GRPC()
    }
}

LKTestWebService.main()
