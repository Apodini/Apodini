import Apodini
import ApodiniHTTP
import ApodiniREST
import ApodiniGRPCv2
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
        let diff = date.timeIntervalSince(Date())
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .spellOut
        return "Hello, \(person.name). You were born \(fmt.localizedString(fromTimeInterval: diff))!"
    }
}

struct Greeter: Handler {
    @Parameter(.http(.path)) var name: String
    
    func handle() async throws -> some ResponseTransformable {
        return "Hello, \(name)!"
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
            .gRPCv2MethodName("root")
        Group("greet") {
            Greeter()
                .gRPCv2MethodName("greet")
        }
        Group("greet2") {
            Greeter2()
                .gRPCv2MethodName("greet2")
        }
        Group("greet_bs") {
            StreamingGreeter_BS()
                .gRPCv2MethodName("greet_bs")
                .pattern(.bidirectionalStream)
        }
        Group("rocket") {
            Rocket()
                .gRPCv2MethodName("rocket")
        }
        Group("rocketBlob") {
            RocketBlob()
                .gRPCv2MethodName("rocketBlob")
        }
        Group("throw") {
            ThrowingHandler()
                .gRPCv2MethodName("throw")
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
        GRPCv2(packageName: "de.lukaskollmer", serviceName: "TestWebService")
//        GRPCv2()
    }
}

LKTestWebService.main()
