//
//  ResponseContainerTests.swift
//
//
//  Created by Paul Schmiedmayer on 2/3/21.
//

@testable import Apodini
import Vapor
import XCTApodini


final class ResponseContainerTests: ApodiniTests {
    private struct ExpectedContent<D: Decodable>: Decodable {
        enum CodingKeys: String, CodingKey {
            case data = "data"
            case links = "_links"
        }
        
        
        var data: D?
        var links: ResponseContainer.Links?
    }
    
    
    private var vaporRequest: Vapor.Request {
        Vapor.Request(application: app.vapor.app, on: app.eventLoopGroup.next())
    }
    
    
    private func getExpectedContent<Content>(
        _ container: ResponseContainer,
        contentType: Content.Type = Content.self
    ) throws -> (HTTPResponseStatus, ExpectedContent<Content>) {
        let response = try container.encodeResponse(for: vaporRequest).wait()
        
        guard let data = response.body.data else {
            return (response.status, ExpectedContent<Content>())
        }
        
        return (response.status, try JSONDecoder().decode(ExpectedContent<Content>.self, from: data))
    }
    
    func testNoContentResponseContainer() throws {
        let (status, recievedContent) = try getExpectedContent(ResponseContainer(Empty.self), contentType: String.self)
        
        XCTAssertEqual(status, .noContent)
        XCTAssertEqual(recievedContent.data, nil)
        XCTAssertEqual(recievedContent.links, nil)
    }
    
    func testOnlyDataResponseContainer() throws {
        let expectedContent = "Paul"
        
        let (status, recievedContent) = try getExpectedContent(ResponseContainer(data: expectedContent), contentType: String.self)
        
        XCTAssertEqual(status, .ok)
        XCTAssertEqual(recievedContent.data, expectedContent)
        XCTAssertEqual(recievedContent.links, nil)
    }
    
    func testOnlyLinksResponseContainer() throws {
        let expectedLinks = ["first": "Paul"]
        
        let (status, recievedContent) = try getExpectedContent(ResponseContainer(Empty.self, links: expectedLinks), contentType: Int.self)
        
        XCTAssertEqual(status, .ok)
        XCTAssertEqual(recievedContent.data, nil)
        XCTAssertEqual(recievedContent.links, expectedLinks)
    }
    
    func testConflictingDataResponseContainer() throws {
        let expectedContent = "Paul"
        
        let (status, recievedContent) = try getExpectedContent(ResponseContainer(status: .noContent, data: expectedContent), contentType: String.self)
        
        XCTAssertEqual(status, .ok)
        XCTAssertEqual(recievedContent.data, expectedContent)
        XCTAssertEqual(recievedContent.links, nil)
    }
    
    func testConflictingLinkResponseContainer() throws {
        let expectedLinks = ["first": "Paul"]
        
        let (status, recievedContent) = try getExpectedContent(
            ResponseContainer(Empty.self, status: .noContent, links: expectedLinks),
            contentType: Int.self
        )
        
        XCTAssertEqual(status, .ok)
        XCTAssertEqual(recievedContent.data, nil)
        XCTAssertEqual(recievedContent.links, expectedLinks)
    }
    
    func testConflictingLinkAndDataResponseContainer() throws {
        let expectedContent = "Paul"
        let expectedLinks = ["first": "Paul"]
        
        let (status, recievedContent) = try getExpectedContent(
            ResponseContainer(status: .noContent, data: expectedContent, links: expectedLinks),
            contentType: String.self
        )
        
        XCTAssertEqual(status, .ok)
        XCTAssertEqual(recievedContent.data, expectedContent)
        XCTAssertEqual(recievedContent.links, expectedLinks)
    }
    
    func testStatusResponseContainer() throws {
        try statusPropagationOfResponseContainer(.ok, expectedStatus: .ok)
        try statusPropagationOfResponseContainer(.ok, expectedStatus: .ok, addContent: false)
        try statusPropagationOfResponseContainer(.noContent, expectedStatus: .ok)
        try statusPropagationOfResponseContainer(.noContent, expectedStatus: .noContent, addContent: false)
        try statusPropagationOfResponseContainer(.created, expectedStatus: .created)
        try statusPropagationOfResponseContainer(.created, expectedStatus: .created, addContent: false)
    }
    
    func statusPropagationOfResponseContainer(_ status: Status, expectedStatus: HTTPStatus, addContent: Bool = true) throws {
        let expectedContent = "Paul"
        
        let (recievedStatus, recievedContent) = try getExpectedContent(
            ResponseContainer(status: status, data: addContent ? expectedContent : nil),
            contentType: String.self
        )
        
        XCTAssertEqual(recievedStatus, expectedStatus)
        XCTAssertEqual(recievedContent.data, addContent ? expectedContent : nil)
        XCTAssertEqual(recievedContent.links, nil)
    }
}
