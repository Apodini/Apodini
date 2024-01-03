import Apodini
import ApodiniHTTP
import ApodiniREST
import ApodiniGRPC
import ApodiniWebSocket
import ApodiniDeployer



struct TextTransformer: InvocableHandler {
    enum Transformation: String, Codable, LosslessStringConvertible {
        case identity
        case capitalize
        case makeLowercase
        case makeUppercase
        case makeSpongebobcase
        
        init?(_ description: String) {
            if let value = Self(rawValue: description) {
                self = value
            } else {
                return nil
            }
        }
        var description: String { rawValue }
    }
    
    class HandlerIdentifier: ScopedHandlerIdentifier<TextTransformer> {
        static let main = HandlerIdentifier("main")
    }
    let handlerId = HandlerIdentifier.main
    
    @Parameter var transformation: Transformation = .identity
    @Parameter var input: String
    
    func handle() -> String {
        switch transformation {
        case .identity:
            return input
        case .capitalize:
            return input
                .split(separator: " ")
                .map { $0.enumerated().map { $0.offset == 0 ? $0.element.uppercased() : String($0.element) }.joined() }
                .joined(separator: " ")
        case .makeLowercase:
            return input.lowercased()
        case .makeUppercase:
            return input.uppercased()
        case .makeSpongebobcase:
            return input.map { .random() ? $0.uppercased() : $0.lowercased() }.joined()
        }
    }
}


//@main
struct WebService: Apodini.WebService {
    struct Greeter: Handler {
        @Apodini.Environment(\.RHI) private var RHI
        
        @Parameter var name: String
        @Parameter var transformation: TextTransformer.Transformation?
        
        func handle() async throws -> String {
            // we use the presence of the transformation parameter to test whether the RHI properly handles default parameter values
            let greetingName: String
            if let transformation = transformation {
                greetingName = try await RHI.invoke(TextTransformer.self, identifiedBy: .main, arguments: [
                    .init(\.$transformation, transformation),
                    .init(\.$input, name)
                ])
            } else {
                greetingName = try await RHI.invoke(TextTransformer.self, identifiedBy: .main, arguments: [
                    .init(\.$input, name)
                ])
            }
            return "Hello \(greetingName)!"
        }
    }
    
    
    struct Adder: InvocableHandler {
        struct ArgumentsStorage: ArgumentsStorageProtocol {
            typealias HandlerType = Adder
            let x: Double
            let y: Double
            
            init(x: Double, y: Double) {
                self.x = x
                self.y = y
            }
            
            init(x: Int, y: Int) {
                self.x = Double(x)
                self.y = Double(y)
            }
            
            static let mapping: [MappingEntry] = [
                .init(from: \.x, to: \.$x),
                .init(from: \.y, to: \.$y)
            ]
        }
        class HandlerIdentifier: ScopedHandlerIdentifier<Adder> {
            static let main = HandlerIdentifier("main")
        }
        
        let handlerId = HandlerIdentifier.main
        
        @Parameter var x: Double
        @Parameter var y: Double
        
        func handle() throws -> Double {
            x + y
        }
    }
    
    struct Calculator: Handler {
        @Apodini.Environment(\.RHI) private var RHI
        
        @Parameter var operation: String
        @Parameter var lhs: Int
        @Parameter var rhs: Int
        
        func handle() async throws -> Int {
            Int(try await RHI.invoke(Adder.self, identifiedBy: .main, arguments: Adder.ArgumentsStorage(x: lhs, y: rhs)))
        }
    }

    
    var content: some Component {
//        Group("_f") {
//            F()
//        }
//        Group("f") {
//            FInvoker()
//        }
        Group("transform", "text") {
            TextTransformer()
        }
        Group("greet") {
            Greeter()
        }
        Group("calc") {
            Calculator()
            Group("add") {
                Adder()
            }
        }
    }
    
    var configuration: any Configuration {
        HTTPConfiguration(
            tlsConfiguration: TLSConfigurationBuilder(
                certificatePath: "/Users/lukas/Documents/uni/apodini certs/2023/localhost.cer.pem",
                keyPath: "/Users/lukas/Documents/uni/apodini certs/2023/localhost.key.pem"
            )
        )
        REST()
        ApodiniDeployer()
    }
}


WebService.main()
