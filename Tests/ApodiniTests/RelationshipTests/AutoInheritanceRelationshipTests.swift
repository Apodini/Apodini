//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import XCTApodini
@testable import Apodini

class AutoInheritanceRelationshipTests: ApodiniTests {
    struct User: Content, Identifiable {
        var id: Int
        var name: String
    }

    struct UserHandler: Handler {
        @Binding
        var userId: Int

        func handle() -> User {
            User(id: userId, name: "Rudi")
        }
    }

    struct AuthenticatedUserHandler: Handler {
        func handle() -> User {
            User(id: 3, name: "Rudi")
        }
    }

    @PathParameter(identifying: User.self)
    var userId: User.ID

    @ComponentBuilder
    var webservice: some Component {
        Group("user", $userId) {
            UserHandler(userId: $userId)
        }
        Group("me") {
            AuthenticatedUserHandler()
        }
    }

    func testAutoInheritance() {
        let context = RelationshipTestContext(app: app, service: webservice)

        let userResult = context.request(on: 1, parameters: 5) // handle /user/userId
        XCTAssertEqual(
            userResult.formatTestRelationships(),
            ["self:read": "/user/5"])

        let meResult = context.request(on: 0) // handle /me
        XCTAssertEqual(
            meResult.formatTestRelationships(),
            ["self:read": "/user/3"])
    }


    struct TypedUserHandler: Handler {
        @Binding
        var type: String
        @Binding
        var userId: Int

        func handle() -> User {
            User(id: userId, name: "Rudi")
        }
    }

    struct TypedAuthenticatedUserHandler: Handler {
        @Binding
        var type: String

        func handle() -> User {
            User(id: 3, name: "Rudi")
        }
    }

    @PathParameter
    var type: String

    @ComponentBuilder
    var typedUserHandler: some Component {
        Group($type) {
            Group("user", $userId) {
                TypedUserHandler(type: $type, userId: $userId)
            }
            Group("me") {
                TypedAuthenticatedUserHandler(type: $type)
            }
        }
    }

    func testTypedInheritance() {
        let context = RelationshipTestContext(app: app, service: typedUserHandler)

        let userResult = context.request(on: 1, parameters: "type0", 5) // handle /user/userId
        XCTAssertEqual(
            userResult.formatTestRelationships(),
            ["self:read": "/type0/user/5"])

        let meResult = context.request(on: 0, parameters: "type0") // handle /me
        XCTAssertEqual(
            meResult.formatTestRelationships(),
            ["self:read": "/type0/user/3"])
    }


    @ComponentBuilder
    var webserviceDefault: some Component {
        Group("user", $userId) {
            UserHandler(userId: $userId)
                .defaultRelationship()
            Group("special") {
                UserHandler(userId: $userId)
            }
        }
        Group("me") {
            AuthenticatedUserHandler()
        }
    }

    func testAutoInheritanceMarkedDefault() {
        let context = RelationshipTestContext(app: app, service: webserviceDefault)

        let userResult = context.request(on: 1, parameters: 5) // handle /user/userId
        XCTAssertEqual(
            userResult.formatTestRelationships(),
            ["self:read": "/user/5", "special:read": "/user/5/special"])

        let meResult = context.request(on: 0) // handle /me
        XCTAssertEqual(
            meResult.formatTestRelationships(),
            ["self:read": "/user/3", "special:read": "/user/3/special"])
    }


    @ComponentBuilder
    var webserviceConflictingDefault: some Component {
        Group("user", $userId) {
            UserHandler(userId: $userId)
                .defaultRelationship()
            Group("special") {
                UserHandler(userId: $userId)
                    .defaultRelationship()
            }
        }
        Group("me") {
            AuthenticatedUserHandler()
        }
    }

    func testAutoInheritanceConflictingMarkedDefault() {
        XCTAssertRuntimeFailure(RelationshipTestContext(app: self.app, service: self.webserviceConflictingDefault),
                                "Annotating the same type twice with defaultRelationship shoudl yield an error!")
    }


    @ComponentBuilder
    var webserviceConflictingTypes: some Component {
        Group("user", $userId) {
            UserHandler(userId: $userId)
        }
        Group("user2", $userId) {
            UserHandler(userId: $userId)
        }
        Group("me") {
            AuthenticatedUserHandler()
        }
    }

    func testAutoInheritanceConflictingTypes() {
        let context = RelationshipTestContext(app: app, service: webserviceConflictingTypes)

        let meResult = context.request(on: 0) // handle /me
        XCTAssertEqual(
            meResult.formatTestRelationships(),
            ["self:read": "/me"])
    }
}
