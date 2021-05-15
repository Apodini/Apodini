//
// Created by Andreas Bauer on 23.01.21.
//

import XCTest
import XCTApodini
@testable import Apodini

class AutoInheritanceRelationshipTests: XCTApodiniDatabaseBirdTest {
    struct User: Content, Equatable, Identifiable {
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
    @PathParameter(identifying: User.self)
    var userId: User.ID
    
    
    func testAutoInheritance() throws {
        @ComponentBuilder
        var webService: some Component {
            Group("user", $userId) {
                UserHandler(userId: $userId)
            }
            Group("me") {
                AuthenticatedUserHandler()
            }
        }
        
        try XCTCheckComponent(
            webService,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<UserHandler>(index: 1) { // handle /user/userId
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/user/5"])
                    }) {
                        UnnamedParameter(5)
                    }
                },
                CheckHandler<AuthenticatedUserHandler>(index: 0) { // handle /me
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/user/3"])
                    })
                }
            ]
        )
    }

    func testTypedInheritance() throws {
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
        
        try XCTCheckComponent(
            typedUserHandler,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<TypedUserHandler>(index: 1) { // handle /user/userId
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/type0/user/5"])
                    }) {
                        UnnamedParameter(5)
                        UnnamedParameter("type0")
                        UnnamedParameter(5)
                    }
                },
                CheckHandler<TypedAuthenticatedUserHandler>(index: 0) { // handle /me
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/type0/user/3"])
                    }) {
                        UnnamedParameter("type0")
                    }
                }
            ]
        )
    }

    func testAutoInheritanceMarkedDefault() throws {
        @ComponentBuilder
        var webService: some Component {
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
        
        try XCTCheckComponent(
            webService,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<UserHandler>(index: 1) { // handle /user/userId
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/user/5", "special:read": "/user/5/special"]
                        )
                    }) {
                        UnnamedParameter(5)
                    }
                },
                CheckHandler<AuthenticatedUserHandler>(index: 0) { // handle /me
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/user/3", "special:read": "/user/3/special"]
                        )
                    })
                }
            ]
        )
    }

    func testAutoInheritanceConflictingMarkedDefault() {
        @ComponentBuilder
        var webService: some Component {
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
        
        
        XCTAssertRuntimeFailure(
            try! self.XCTCheckComponent(
                webService,
                exporter: RelationshipExporter(self.app),
                interfaceExporterVisitors: [RelationshipExporterRetriever()]
            ),
            "Annotating the same type twice with defaultRelationship shoudl yield an error!"
        )
    }
    
    func testAutoInheritanceConflictingTypes() throws {
        @ComponentBuilder
        var webService: some Component {
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
        
        try XCTCheckComponent(
            webService,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<AuthenticatedUserHandler>(index: 0) { // handle /me
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/me"])
                    })
                }
            ]
        )
    }
}
