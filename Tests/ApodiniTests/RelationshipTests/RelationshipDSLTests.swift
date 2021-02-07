//
// Created by Andreas Bauer on 24.01.21.
//

import XCTest
import XCTApodini
@testable import Apodini

class RelationshipDSLTests: ApodiniTests {
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

    struct AuthenticatedUser: Content, WithRelationships, Identifiable {
        var id: Int
        var secretName: String

        static var relationships: Relationships {
            Inherits<User>()
        }
    }

    struct Post: Content, Identifiable {
        var id: Int
        var title: String
    }

    struct TestA: Content {
        var info: String
    }

    struct TestB: Content {
        var info: String
    }

    struct TestC: Content, Identifiable {
        var id: Int
    }

    struct UserHandler: Handler {
        @Parameter
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
        @Parameter
        var userId: Int
        @Parameter
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
        @Parameter
        var param: String
        func handle() -> TestB {
            TestB(info: "TestB Info")
        }
    }

    struct TestCHandler: Handler {
        @Parameter
        var cId: Int
        func handle() -> TestC {
            TestC(id: cId)
        }
    }

    @PathParameter(identifying: User.self)
    var userId: User.ID
    @PathParameter(identifying: Post.self)
    var postId: User.ID
    @PathParameter
    var param: String
    @PathParameter(identifying: TestC.self)
    var cParam: Int

    @ComponentBuilder
    var webservice: some Component {
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

    func testWebservice() {
        let context = RelationshipTestContext(app: app, service: webservice)

        let authenticatedResult = context.request(on: 0)
        XCTAssertEqual(
            authenticatedResult.formatTestRelationships(),
            [
                "self:read": "/user/5", "tagged:read": "/user/5/post/{postId}", "post:read": "/user/5/post/{postId}",
                "TestA:read": "/xTestA", "TestB:read": "/xTestB/{param}", "TestC:read": "/xTestC/{cId}"
            ])

        let userResult = context.request(on: 2, parameters: 3)
        XCTAssertEqual(
            userResult.formatTestRelationships(),
            [
                "self:read": "/user/3", "tagged:read": "/user/3/post/9", "post:read": "/user/3/post/{postId}",
                "TestA:read": "/xTestA", "TestC:read": "/xTestC/28"
            ])

        let postResult = context.request(on: 3, parameters: 3, 10)
        XCTAssertEqual(
            postResult.formatTestRelationships(),
            ["self:read": "/user/3/post/10"])

        // below test case properly ensures that inherited relationships won't shadow the same existing relationship.
        let meResult = context.request(on: 1)
        XCTAssertEqual(
            meResult.formatTestRelationships(),
            [
                "self:read": "/user/123", "tagged:read": "/user/123/post/1234", "post:read": "/user/123/post/{postId}",
                "TestA:read": "/xTestA", "TestC:read": "/xTestC/12345"
            ])
    }

    struct Referencing: Content, WithRelationships {
        var referenced: String?

        static var relationships: Relationships {
            References<Referenced>(as: "referenced", identifiedBy: \.referenced)
        }
    }

    struct Referenced: Content, Identifiable {
        var id: String
    }

    struct ReferencingHandler: Handler {
        @Parameter
        var referenced: String?
        func handle() -> Referencing {
            Referencing(referenced: referenced)
        }
    }

    struct ReferencedHandler: Handler {
        @Parameter
        var id: String
        func handle() -> Referenced {
            Referenced(id: id)
        }
    }

    @PathParameter(identifying: Referenced.self)
    var refId: String

    @ComponentBuilder
    var optionalReferenceWebService: some Component {
        Group("referencing") {
            ReferencingHandler() // 1
        }
        Group("referenced", $refId) {
            ReferencedHandler(id: $refId) // 0
        }
    }

    func testOptionalReference() {
        let context = RelationshipTestContext(app: app, service: optionalReferenceWebService)

        let resultNil = context.request(on: 1, parameters: nil)
        XCTAssertEqual(
            resultNil.formatTestRelationships(),
            ["self:read": "/referencing", "referenced:read": "/referenced/{id}"])

        let resultRef = context.request(on: 1, parameters: "RefID")
        XCTAssertEqual(
            resultRef.formatTestRelationships(),
            ["self:read": "/referencing", "referenced:read": "/referenced/RefID"])
    }

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
    var duplicatedInheritsWebservice: some Component {
        Group("duplicates") {
            DuplicatesHandler()
        }
    }

    func testInheritsDuplicates() {
        XCTAssertRuntimeFailure(RelationshipTestContext(app: self.app, service: self.duplicatedInheritsWebservice),
                                "Duplicate Inherits definition must fail!")
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

    @ComponentBuilder
    var unresolvedInheritsWebservice: some Component {
        Group("unresolved") {
            UnresolvedHandler()
        }
    }

    func testUnresolvedInherits() {
        XCTAssertRuntimeFailure(RelationshipTestContext(app: self.app, service: self.unresolvedInheritsWebservice),
                                "Inherits definition with unknown type must fail")
    }


    struct TextWithParameter: Handler {
        @Parameter(.http(.path))
        var textID: String
        var text: String
        func handle() -> String {
            text
        }
    }

    @ComponentBuilder
    var missingResolverWebService: some Component {
        Group("missingResolver") {
            UnresolvedHandler()
        }
        Group("someString") {
            TextWithParameter(text: "test")
        }
    }

    func testMissingResolverWebService() {
        XCTAssertRuntimeFailure(RelationshipTestContext(app: self.app, service: self.missingResolverWebService),
                                "Inherits with missing resolver for destination must fail.")
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

    struct User2Handler: Handler {
        @Parameter
        var userId: User2.ID
        func handle() -> User2 {
            User2(id: userId, taggedPost: 4)
        }
    }
    struct Post2Handler: Handler {
        @Parameter
        var userId: User2.ID
        @Parameter
        var postId: Post2.ID
        func handle() -> Post2 {
            Post2(id: postId, writtenBy: 7)
        }
    }

    @PathParameter(identifying: User2.self)
    var user2Id: User2.ID
    @PathParameter(identifying: Post2.self)
    var post2Id: Post2.ID

    @ComponentBuilder
    var conflictingResolversWebService: some Component {
        Group("user", $user2Id) {
            User2Handler(userId: $user2Id) // 0
            Group("post", $post2Id) {
                Post2Handler(userId: $user2Id, postId: $post2Id) // 1
            }
        }
    }

    func testCyclicReferencesDefinition() {
        let context = RelationshipTestContext(app: app, service: conflictingResolversWebService)

        let resultNil = context.request(on: 0, parameters: 76)
        XCTAssertEqual(
            resultNil.formatTestRelationships(),
            ["self:read": "/user/76", "post:read": "/user/76/post/{postId}", "taggedPost:read": "/user/76/post/4"])

        let resultRef = context.request(on: 1, parameters: 56, 89)
        XCTAssertEqual(
            resultRef.formatTestRelationships(),
            ["self:read": "/user/56/post/89", "author:read": "/user/7"])
    }
}
