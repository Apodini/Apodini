//
//  TestWebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

@testable import Apodini
import Vapor
import NIO
import Runtime


struct TestWebService: Apodini.WebService {
    struct SomeStruct: Vapor.Content {
        var someProp: Int
        var optionalInt: Int?
        var optionalString: String?
        var reqDouble: Double
    }

    struct SomeComp: Handler {
        @Parameter
        var name: String?

        func handle() -> SomeStruct {
            SomeStruct(someProp: 4, reqDouble: 5.0)
        }
    }

    struct User: Codable {
        var id: Int
        var name: String?
    }

    struct UserHandler: Handler {
        @Parameter var userId: Int

        func handle() -> User {
            User(id: userId)
        }
    }

    @PathParameter var userId: Int

    var content: some Component {
        Group("complexHandler") {
            SomeComp()
        }
        Group("user", $userId) {
            UserHandler(userId: $userId)
                    .operation(.update)
        }
    }
}

TestWebService.main()
