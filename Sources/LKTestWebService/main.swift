//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

// swiftlint:disable all

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
    
    func handle() -> Response<String> {
        print("GREETER. name: \(name), names: \(names), connection: \(connection) (state: \(connection.state))")
        switch connection.state {
        case .open:
            names.append(name)
            return .send()
        case .end:
            names.append(name)
            fallthrough
        case .close:
            switch names.count {
            case 0:
                return .final("Hello!")
            case 1:
                return .final("Hello, \(names[0])")
            default:
                return .final("Hello, \(names[0..<(names.endIndex - 1)].joined(separator: ", ")), and \(names.last!)")
            }
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




struct BlockBasedHandler<T: Apodini.ResponseTransformable>: Handler {
    let imp: () async throws -> T
    func handle() async throws -> T {
        try await imp()
    }
}



struct WrappedArray: Codable, Apodini.Content {
    let values: [String]
}

struct WrappedArrayReturningHandler: Handler {
    func handle() async throws -> WrappedArray {
        .init(values: ["a", "b", "c", "d", "e"])
    }
}

struct EchoHandler<Input: Codable & ResponseTransformable>: Handler {
    @Parameter var input: Input
    func handle() async throws -> some ResponseTransformable {
        input
    }
}




struct City: Codable, ResponseTransformable {
    let name: String
    let country: String
}


//struct GenericStruct<T> {
enum Color: Int32, ProtobufEnum, ResponseTransformable {
    case white, black, orange, blue, red
}
//}


struct ColorMappingHandler_Str2Col: Handler {
    @Parameter var colorName: String
    func handle() async throws -> Color {
        switch colorName.lowercased() {
        case "white":
            return .white
        case "black":
            return .black
        case "orange":
            return .orange
        case "blue":
            return .blue
        case "red":
            return .red
        default:
            return .orange
        }
    }
}


struct ColorMappingHandler_Col2Str: Handler {
//    enum Color: Int32, ProtobufEnum, ResponseTransformable {
//        case white, black, orange, blue, red
//    }
    @Parameter var color: Color
    func handle() async throws -> String {
        switch color {
        case .white: return "white"
        case .black: return "black"
        case .orange: return "orange"
        case .blue: return "blue"
        case .red: return "red"
        }
    }
}


struct LKTestWebService: Apodini.WebService {
    var content: some Component {
        Text("Hello World!")
            .gRPCMethodName("root")
            .operation(.create)
//        Group("greet") {
//            Greeter()
//                .gRPCMethodName("greet")
//        }
//        Group("greet2") {
//            Greeter2()
//                .gRPCMethodName("greet2")
//        }
//        Group("greet_cs") {
//            StreamingGreeter_CS()
//                .gRPCMethodName("greet_cs")
//                .pattern(.clientSideStream)
//        }
//        Group("greet_bs") {
//            StreamingGreeter_BS()
//                .gRPCMethodName("greet_bs")
//                .pattern(.bidirectionalStream)
//        }
//        Group("rocket") {
//            Rocket()
//                .gRPCMethodName("rocket")
//        }
//        Group("rocketBlob") {
//            RocketBlob()
//                .gRPCMethodName("rocketBlob")
//        }
//        Group("throw") {
//            ThrowingHandler()
//                .gRPCMethodName("throw")
//        }
//        Group("api") {
//            Text("A").gRPCMethodName("GetPost")
//            Text("B").gRPCMethodName("AddPost")
//            Text("C").gRPCMethodName("DeletePost")
//            BlockBasedHandler<[String]> { ["", "a", "b", "c", "d"] }.gRPCMethodName("ListPosts")
//            //BlockBasedHandler<WrappedArray> { .init(values: ["", "a", "b", "c", "d"]) }.gRPCMethodName("ListPosts2")
//            //WrappedArrayReturningHandler().gRPCMethodName("ListPosts2")
//            BlockBasedHandler<Int> { 1 }.gRPCMethodName("GetAnInt")
//            BlockBasedHandler<[Int]> { [0, 1, 2, 3, 4, -52] }.gRPCMethodName("ListIDs")
//            ColorMappingHandler_Str2Col().gRPCMethodName("GetColorFromName")
//            ColorMappingHandler_Col2Str().gRPCMethodName("GetColorName")
//        }.gRPCServiceName("API")
//        EchoHandler<String>().gRPCMethodName("EchoString")
//        EchoHandler<Int>().gRPCMethodName("EchoInt")
//        EchoHandler<[Double]>().gRPCMethodName("EchoDoubles")
//        EchoHandler<City>().gRPCMethodName("EchoCity")
    }
    
    var configuration: Configuration {
        HTTPConfiguration(
            //hostname: .init(address: "localhost", port: 50001),
            bindAddress: .interface("localhost", port: 50001)
//            tlsConfigurationBuilder: TLSConfigurationBuilder(
//                certificatePath: "/Users/lukas/Documents/apodini certs/localhost.cer.pem",
//                keyPath: "/Users/lukas/Documents/apodini certs/localhost.key.pem"
//            )
        )
//        HTTP2Configuration(
//            cert: "/Users/lukas/Documents/apodini certs/localhost.cer.pem",
//            keyPath: "/Users/lukas/Documents/apodini certs/localhost.key.pem"
//        )
        ApodiniHTTP.HTTP()
        //HTTP2Configuration(cert: <#T##String?#>, keyPath: <#T##String?#>)
        //HTTPConfiguration(hostname: "localhost")
//        REST()
//        GRPC(packageName: "de.lukaskollmer", serviceName: "TestWebService")
//        GRPC()
    }
}

LKTestWebService.main()
