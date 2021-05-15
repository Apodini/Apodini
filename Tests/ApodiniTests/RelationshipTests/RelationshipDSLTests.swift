//
// Created by Andreas Bauer on 24.01.21.
//

import XCTest
import XCTApodini
@testable import Apodini

class RelationshipDSLTests: XCTApodiniDatabaseBirdTest {
    struct TestA: Content {
        var info: String
    }
    
    struct TestC: Content, Identifiable {
        var id: Int
    }
    
    struct User: Content, WithRelationships, Identifiable {
        var id: Int
        var name: String
        var taggedPost: Int
        var cId: Int

        static var relationships: Relationships {
            References<Post>(as: "tagged", identifiedBy: \.taggedPost)
            Relationship(name: "TestA", to: TestA.self)
            Relationship(name: "TestC", to: TestC.self, parameter: \.cId)
        }
    }

    struct Post: Content, Identifiable {
        var id: Int
        var title: String
    }
    
    @PathParameter(identifying: User.self)
    var userId: User.ID
    @PathParameter(identifying: Post.self)
    var postId: User.ID
    @PathParameter
    var param: String
    @PathParameter(identifying: TestC.self)
    var cParam: Int
    
    
    func testWebservice() throws {
        struct AuthenticatedUser: Content, WithRelationships, Identifiable {
            var id: Int
            var secretName: String

            static var relationships: Relationships {
                Inherits<User>()
            }
        }

        struct TestB: Content {
            var info: String
        }

        struct UserHandler: Handler {
            @Binding
            var userId: Int

            func handle() -> User {
                User(id: userId, name: "Rudi", taggedPost: 9, cId: 28)
            }
        }

        struct AuthenticatedUserHandler: Handler {
            func handle() -> AuthenticatedUser {
                AuthenticatedUser(id: 5, secretName: "Secret Rudi")
            }
        }

        struct MeUserHandler: Handler {
            func handle() -> User {
                User(id: 123, name: "Freddy", taggedPost: 1234, cId: 12345)
            }
        }

        struct PostHandler: Handler {
            @Binding
            var userId: Int
            @Binding
            var postId: Int

            func handle() -> Post {
                Post(id: postId, title: "Test Title")
            }
        }

        struct TestAHandler: Handler {
            func handle() -> TestA {
                TestA(info: "Test Info")
            }
        }

        struct TestBHandler: Handler {
            @Binding
            var param: String
            
            
            func handle() -> TestB {
                TestB(info: "TestB Info")
            }
        }

        struct TestCHandler: Handler {
            @Binding
            var cId: Int
            
            
            func handle() -> TestC {
                TestC(id: cId)
            }
        }

        
        @ComponentBuilder
        var webService: some Component {
            Group("user", $userId) {
                UserHandler(userId: $userId) // 2
                Group("post", $postId) {
                    PostHandler(userId: $userId, postId: $postId) // 3
                }
            }
            Group("xTestA") {
                TestAHandler()
            }
            Group("xTestB", $param) {
                TestBHandler(param: $param)
            }
            Group("xTestC", $cParam) {
                TestCHandler(cId: $cParam)
            }
            Group("authenticated") {
                AuthenticatedUserHandler() // 0
                    .relationship(name: "TestB", to: TestB.self)
            }
            Group("me") {
                MeUserHandler() // 1
            }
        }
        
        try XCTCheckComponent(
            webService,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<MeUserHandler>(index: 0) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            [
                                "self:read": "/user/5", "tagged:read": "/user/5/post/{postId}", "post:read": "/user/5/post/{postId}",
                                "TestA:read": "/xTestA", "TestB:read": "/xTestB/{param}", "TestC:read": "/xTestC/{cId}"
                            ]
                        )
                    })
                },
                CheckHandler<MeUserHandler>(index: 2) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            [
                                "self:read": "/user/3", "tagged:read": "/user/3/post/9", "post:read": "/user/3/post/{postId}",
                                "TestA:read": "/xTestA", "TestC:read": "/xTestC/28"
                            ]
                        )
                    }) {
                        UnnamedParameter(3)
                    }
                },
                CheckHandler<MeUserHandler>(index: 3) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/user/3/post/10"]
                        )
                    }) {
                        UnnamedParameter(3)
                        UnnamedParameter(10)
                    }
                },
                CheckHandler<MeUserHandler>(index: 1) { // below test case properly ensures that inherited relationships won't shadow the same existing relationship.
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            [
                                "self:read": "/user/123", "tagged:read": "/user/123/post/1234", "post:read": "/user/123/post/{postId}",
                                "TestA:read": "/xTestA", "TestC:read": "/xTestC/12345"
                            ]
                        )
                    })
                }
            ]
        )
    }
    

    struct Referenced: Content, Identifiable {
        var id: String
    }
    
    @PathParameter(identifying: Referenced.self)
    var refId: String
    
    func testOptionalReference() throws {
        struct Referencing: Content, WithRelationships {
            var referenced: String?

            static var relationships: Relationships {
                References<Referenced>(as: "referenced", identifiedBy: \.referenced)
            }
        }

        struct ReferencingHandler: Handler {
            @Parameter
            var referenced: String?
            func handle() -> Referencing {
                Referencing(referenced: referenced)
            }
        }

        struct ReferencedHandler: Handler {
            @Binding
            var id: String
            
            func handle() -> Referenced {
                Referenced(id: id)
            }
        }
        
        
        @ComponentBuilder
        var webService: some Component {
            Group("referencing") {
                ReferencingHandler() // 1
            }
            Group("referenced", $refId) {
                ReferencedHandler(id: $refId) // 0
            }
        }
        
        try XCTCheckComponent(
            webService,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<ReferencingHandler>(index: 1) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/referencing", "referenced:read": "/referenced/{id}"]
                        )
                    }) {
                        UnnamedParameter<Empty>(nil)
                    }
                },
                CheckHandler<ReferencingHandler>(index: 1) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/referencing", "referenced:read": "/referenced/RefID"]
                        )
                    }) {
                        UnnamedParameter("RefID")
                    }
                }
            ]
        )
    }

    func testInheritsDuplicates() {
        struct Duplicates: Content, WithRelationships {
            static var relationships: Relationships {
                Inherits<String>()
                Inherits<Int>()
            }
        }

        struct DuplicatesHandler: Handler {
            func handle() -> Duplicates {
                Duplicates()
            }
        }

        @ComponentBuilder
        var webService: some Component {
            Group("duplicates") {
                DuplicatesHandler()
            }
        }
        
        XCTAssertRuntimeFailure(
            try! self.XCTCheckComponent(
                webService,
                exporter: RelationshipExporter(self.app),
                interfaceExporterVisitors: [RelationshipExporterRetriever()]
            ),
            "Duplicate Inherits definition must fail!"
        )
    }
    
    struct Unresolved: Content, WithRelationships {
        static var relationships: Relationships {
            Inherits<String>()
        }
    }

    struct UnresolvedHandler: Handler {
        func handle() -> Unresolved {
            Unresolved()
        }
    }

    func testUnresolvedInherits() {
        @ComponentBuilder
        var webService: some Component {
            Group("unresolved") {
                UnresolvedHandler()
            }
        }
        
        XCTAssertRuntimeFailure(
            try! self.XCTCheckComponent(
                webService,
                exporter: RelationshipExporter(self.app),
                interfaceExporterVisitors: [RelationshipExporterRetriever()]
            ),
            "Inherits definition with unknown type must fail"
        )
    }

    func testMissingResolverWebService() {
        struct TextWithParameter: Handler {
            @Parameter(.http(.path))
            var textID: String
            var text: String
            func handle() -> String {
                text
            }
        }

        @ComponentBuilder
        var webService: some Component {
            Group("missingResolver") {
                UnresolvedHandler()
            }
            Group("someString") {
                TextWithParameter(text: "test")
            }
        }
        
        
        XCTAssertRuntimeFailure(
            try! self.XCTCheckComponent(
                webService,
                exporter: RelationshipExporter(self.app),
                interfaceExporterVisitors: [RelationshipExporterRetriever()]
            ),
            "Inherits with missing resolver for destination must fail."
        )
    }

    struct User2: Content, WithRelationships, Identifiable {
        var id: Int
        var taggedPost: Post2.ID

        static var relationships: Relationships {
            References<Post2>(as: "taggedPost", identifiedBy: \.taggedPost)
        }
    }

    struct Post2: Content, WithRelationships, Identifiable {
        var id: Int
        var writtenBy: User2.ID

        static var relationships: Relationships {
            References<User2>(as: "author", identifiedBy: \.writtenBy)
        }
    }
    
    @PathParameter(identifying: User2.self)
    var user2Id: User2.ID
    @PathParameter(identifying: Post2.self)
    var post2Id: Post2.ID

    func testCyclicReferencesDefinition() throws {
        struct User2Handler: Handler {
            @Binding
            var userId: User2.ID
            
            
            func handle() -> User2 {
                User2(id: userId, taggedPost: 4)
            }
        }
        
        struct Post2Handler: Handler {
            @Binding
            var userId: User2.ID
            @Binding
            var postId: Post2.ID
            
            
            func handle() -> Post2 {
                Post2(id: postId, writtenBy: 7)
            }
        }
        
        @ComponentBuilder
        var webService: some Component {
            Group("user", $user2Id) {
                User2Handler(userId: $user2Id) // 0
                Group("post", $post2Id) {
                    Post2Handler(userId: $user2Id, postId: $post2Id) // 1
                }
            }
        }
        
        try XCTCheckComponent(
            webService,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<User2Handler>(index: 0) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/user/76", "post:read": "/user/76/post/{postId}", "taggedPost:read": "/user/76/post/4"]
                        )
                    }) {
                        UnnamedParameter(76)
                    }
                },
                CheckHandler<Post2Handler>(index: 1) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/user/56/post/89", "author:read": "/user/7"]
                        )
                    }) {
                        UnnamedParameter(56)
                        UnnamedParameter(89)
                    }
                }
            ]
        )
    }
}
