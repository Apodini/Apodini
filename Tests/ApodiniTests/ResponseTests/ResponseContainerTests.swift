//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
@testable import ApodiniREST
import XCTApodini
@testable import ApodiniNetworking


final class ResponseContainerTests: ApodiniTests {
    private struct ExpectedContent<D: Decodable>: Decodable {
        enum CodingKeys: String, CodingKey {
            case data = "data"
            case links = "_links"
        }
        
        
        var data: D?
        var links: ResponseContainer.Links?
    }
    
    
    private func getExpectedContent<Content>(
        _ container: ResponseContainer,
        contentType: Content.Type = Content.self
    ) throws -> (HTTPResponseStatus, ExpectedContent<Content>) {
        let request = HTTPRequest(
            remoteAddress: nil,
            version: .http1_1,
            method: .GET,
            url: .init(string: "/")!,
            headers: [:],
            eventLoop: app.eventLoopGroup.next()
        )
        let response = try container.encodeResponse(for: request).wait()
        
        guard let data = response.bodyStorage.readNewData(), !data.isEmpty else {
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
    
    
    func statusPropagationOfResponseContainer(_ status: Status, expectedStatus: HTTPResponseStatus, addContent: Bool = true) throws {
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
