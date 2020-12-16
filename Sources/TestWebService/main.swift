//
//  TestWebService.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

@testable import Apodini
import Vapor
import NIO



// MARK: Model



struct Account: Vapor.Content {
    let handle: String
    let name: String
}



struct Tweet: Vapor.Content {
    let text: String
}








// MARK: Account


struct GetAccount: EndpointNode {
    @Parameter("id")
    var id: String
    
    class EndpointIdentifier: ScopedEndpointIdentifier<GetAccount> {
        static let `default` = EndpointIdentifier("default")
    }

    let __endpointId: EndpointIdentifier = .default
    
    func handle() -> Account {
        fatalError()
    }
}




struct GetTweets: EndpointNode {
    class EndpointIdentifier: ScopedEndpointIdentifier<GetTweets> {
        static let `default` = GetTweets.EndpointIdentifier("default")
    }
    
    static var outgoingDependencies: Set<AnyEndpointIdentifier> {
        return [GetAccount.EndpointIdentifier.default]
    }
    
    let __endpointId = EndpointIdentifier.default
    
    func handle() -> [Tweet] {
        fatalError()
        return []
    }
}











struct PostTweet: EndpointNode {
    enum OperationMode {
        case normal, legacy
    }
    
    class EndpointIdentifier: ScopedEndpointIdentifier<PostTweet> {
        static let normal = EndpointIdentifier("normal")
        static let legacy = EndpointIdentifier("legacy")
    }
    
    
    let __endpointId: EndpointIdentifier
    let maxLength: Int
    
    init(mode: OperationMode) {
        switch mode {
        case .normal:
            __endpointId = .normal
            maxLength = 280
        case .legacy:
            __endpointId = .legacy
            maxLength = 140
        }
    }
    
    
    func handle() -> HTTPStatus {
        fatalError()
        print("-[\(Self.self) \(#function)]")
        return .created
    }
}








struct TestWebService2: WebService {
    var content: some EndpointProvidingNode {
        Group("account") {
            GetAccount()
        }
        Group("tweet") {
            GetTweets()
                .operation(.read)
            PostTweet(mode: .legacy)
                .operation(.create)
        }
        Group("test") {
            Text("owo")
            Text("uwu")
        }
    }
}








//let webService = TestWebService2()
//let constraintSystem = LKConstraintSystem(webService: webService)
//print(try! constraintSystem.solve())


//TestWebService2.main()










struct NEW_Greeter: EndpointNode {
    //@Parameter("name", .http(.query))
    //var name: String
    
    @_Request
    var req: Vapor.Request
    
    func handle() -> String {
        if let name = try? req.query.get(String.self, at: "name") {
            return "Hallo \(name)!"
        } else {
            return "Hwllo!"
        }
    }
}



struct NEW_TestWebService: WebService {
    var content: some EndpointProvidingNode {
        Group("test") {
            NEW_Greeter()
            Group("nested") {
                NEW_Greeter()
            }
        }
        Group {
            NEW_Greeter()
        }
    }
}




NEW_TestWebService.main()


