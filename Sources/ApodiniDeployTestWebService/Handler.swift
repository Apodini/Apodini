import Apodini
import ApodiniDeploy
import ApodiniOpenAPI
import ApodiniREST
import DeploymentTargetLocalhostRuntime
import DeploymentTargetAWSLambdaRuntime
import Foundation
import NIO

// We prefix some types with 'LH_' and 'AWS_' to indicate whether they belong to
// the localhost or the AWS part of the tests. Yeah the underscore isn't excatly ideal but it makes
// differentiating between the two kinds of components a lot easier...
// swiftlint:disable type_name

// MARK: - Text Handler

struct TextHandler: Handler {
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    func handle() -> String {
        text
    }
}


// MARK: - Localhost Components

struct LH_ResponseWithPid<T: Codable>: Content, Codable {
    let pid: pid_t
    let value: T

    init(_ value: T) {
        self.pid = getpid()
        self.value = value
    }
}


struct LH_TextMut: InvocableHandler {
    class HandlerIdentifier: ScopedHandlerIdentifier<LH_TextMut> {
        static let main = HandlerIdentifier("main")
    }
    let handlerId: HandlerIdentifier = .main
    
    @Parameter var text: String
    
    func handle() -> LH_ResponseWithPid<String> {
        LH_ResponseWithPid(text.lowercased())
    }
}


struct LH_GreeterResponse: Codable {
    let text: String
    let textMutPid: pid_t
}

struct LH_Greeter: Handler {
    @Apodini.Environment(\.RHI) private var RHI
    
    @Parameter(.http(.path)) var name: String
    
    func handle() -> EventLoopFuture<LH_ResponseWithPid<LH_GreeterResponse>> {
        RHI.invoke(
            LH_TextMut.self,
            identifiedBy: .main,
            arguments: [.init(\.$text, name)]
        )
        .map { response -> LH_ResponseWithPid<LH_GreeterResponse> in
            LH_ResponseWithPid(LH_GreeterResponse(
                text: "Hello, \(response.value)!",
                textMutPid: response.pid
            ))
        }
    }
}


// MARK: - Lambda Components

struct AWS_RandomNumberGenerator: InvocableHandler, HandlerWithDeploymentOptions {
    class HandlerIdentifier: ScopedHandlerIdentifier<AWS_RandomNumberGenerator> {
        static let main = HandlerIdentifier("main")
        static let other = HandlerIdentifier("other")
    }
    let handlerId: HandlerIdentifier
    let ugh: Int = 12
    
    @Parameter var lowerBound: Int = 0
    @Parameter var upperBound: Int = .max
    
    func handle() throws -> Int {
        print("\(Self.self) invoked at pid \(getpid())")
        guard lowerBound <= upperBound else {
            throw NSError(domain: "ApodiniDeployTestWebService", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Invalid bounds. Got \(lowerBound)...\(upperBound)"
            ])
        }
        return Int.random(in: lowerBound...upperBound)
    }
    
    static var deploymentOptions: [AnyDeploymentOption] {
        // NOTE: starting with swift 5.4 we'll be able to drop the leading `AnyOption` here and use the implicit member thing w/ chaining
        [
            AnyDeploymentOption.memory(.mb(150)).when(\Self.handlerId == .main),
            AnyDeploymentOption.memory(.mb(180)).when(\Self.handlerId == .other),
            AnyDeploymentOption.timeout(.seconds(12))
        ]
    }
}


struct AWS_Greeter: Handler {
    @Apodini.Environment(\.RHI) private var RHI
    
    @Parameter private var age: Int
    @Parameter(.http(.path)) var name: String
    
    func handle() -> EventLoopFuture<String> {
        RHI.invoke(
            AWS_RandomNumberGenerator.self,
            identifiedBy: .main,
            arguments: [
                .init(\.$lowerBound, age),
                .init(\.$upperBound, age * 2)
            ]
        )
        .map { randomNumber -> String in
            "Hello, \(name). Your random number in range \(age)...\(2 * age) is \(randomNumber)!"
        }
    }
}
