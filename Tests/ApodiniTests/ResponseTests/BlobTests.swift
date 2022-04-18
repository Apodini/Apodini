//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTApodini
@testable import ApodiniREST
@testable import Apodini
@testable import ApodiniOpenAPI
@testable import ApodiniNetworking
@testable import ApodiniHTTP


final class BlobTests: ApodiniTests {
    func testBlobResponseHandler() throws {
        struct BlobResponseHandler: Handler {
            @Parameter var mediaType: HTTPMediaType
            
            func handle() -> Blob {
                Blob(Data(), type: mediaType)
            }
        }
        
        let handler = BlobResponseHandler().inject(app: app)
        let endpoint = handler.mockEndpoint()

        let mediaTypes = [
            HTTPMediaType.text(.html, parameters: ["Test": "Test"]),
            HTTPMediaType.application(.json),
            HTTPMediaType.image(.gif),
            HTTPMediaType(type: "application", subtype: "pkcs8", parameters: ["Test": "Test"])
        ]
        
        let exporter = MockExporter<String>(queued: mediaTypes[0], mediaTypes[1], mediaTypes[2], mediaTypes[3])
        let context = endpoint.createConnectionContext(for: exporter)

        try XCTCheckResponse(
            context.handle(request: "", eventLoop: app.eventLoopGroup.next()),
            content: Blob(Data(), type: mediaTypes[0]),
            connectionEffect: .close
        )
        
        try XCTCheckResponse(
            context.handle(request: "", eventLoop: app.eventLoopGroup.next()),
            content: Blob(Data(), type: mediaTypes[1]),
            connectionEffect: .close
        )
        
        try XCTCheckResponse(
            context.handle(request: "", eventLoop: app.eventLoopGroup.next()),
            content: Blob(Data(), type: mediaTypes[2]),
            connectionEffect: .close
        )
        
        try XCTCheckResponse(
            context.handle(request: "", eventLoop: app.eventLoopGroup.next()),
            content: Blob(Data(), type: mediaTypes[3]),
            connectionEffect: .close
        )
    }
    
    func testBlobRESTEndpointHandler() throws {
        struct BlobResponseHandler: Handler {
            @Parameter var name: String
            @Parameter var mediaType: HTTPMediaType
            
            func handle() -> Apodini.Response<Blob> {
                .send(Blob(Data(name.utf8), type: mediaType), status: .ok)
            }
        }
        
        let handler = BlobResponseHandler()
        let (endpoint, rendpoint) = handler.mockRelationshipEndpoint(app: app)
        
        let exporter = RESTInterfaceExporter(app)
        let endpointHandler = RESTEndpointHandler(
            with: app,
            withExporterConfiguration: HTTPExporterConfiguration(),
            for: endpoint,
            rendpoint,
            on: exporter
        )
        
        
        func makeRequest(blobContent: String, mediaType: HTTPMediaType) throws {
            let request = HTTPRequest(
                remoteAddress: nil,
                version: .http1_1,
                method: .POST,
                url: URI(string: "https://ase.in.tum.de/schmiedmayer?name=\(blobContent)")!,
                headers: [:],
                bodyStorage: .buffer(initialValue: try JSONEncoder().encode(mediaType)),
                eventLoop: app.eventLoopGroup.next()
            )
            let response = try endpointHandler.respond(to: request).makeHTTPResponse(for: request).wait()
            let responseString = try XCTUnwrap(response.bodyStorage.readNewDataAsString())
            XCTAssertEqual(responseString, blobContent)
        }

        try makeRequest(blobContent: "Nadine", mediaType: .application(.json))
        try makeRequest(blobContent: "Paul", mediaType: .text(.plain, parameters: ["User": "Paul"]))
        try makeRequest(blobContent: "Bernd", mediaType: .image(.gif))
    }
    
    func testBlobAndMimeTypeWithOpenAPIExporter() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        
        let blobResponse = try componentsBuilder.buildResponse(for: Blob.self)
        XCTAssertEqual(.reference(.component(named: "DataResponse")), blobResponse)
        
        let blobSchema = try componentsBuilder.buildSchema(for: Blob.self)
        XCTAssertEqual(blobSchema, .string(format: .binary))
        
        let mimeTypeResponse = try componentsBuilder.buildResponse(for: HTTPMediaType.self)
        XCTAssertEqual(.reference(.component(named: "HTTPMediaTypeResponse")), mimeTypeResponse)
        
        let mimeTypeSchema = try componentsBuilder.buildSchema(for: HTTPMediaType.self)
        XCTAssertEqual(.reference(.component(named: "HTTPMediaType")), mimeTypeSchema)
    }
    
    func testBlobEncoding() throws {
        let blob = Blob(Data("Paul".utf8), type: .text(.plain))
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedBlob = try XCTUnwrap(String(data: try encoder.encode(blob), encoding: .utf8))
        
        XCTAssert(encodedBlob.contains(#""data" : "UGF1bA==""#))
        XCTAssert(encodedBlob.contains(#""type" : "text""#))
        XCTAssert(encodedBlob.contains(#""subtype" : "plain""#))
    }
    
    func testMIMEToAndFromString() throws {
        let stringEncodedMimeType = try XCTUnwrap(HTTPMediaType("text/plain;test=test;test2=test"))
        
        XCTAssertEqual(stringEncodedMimeType.type, "text")
        XCTAssertEqual(stringEncodedMimeType.subtype, "plain")
        XCTAssertEqual(stringEncodedMimeType.parameters["test"], "test")
        XCTAssertEqual(stringEncodedMimeType.parameters["test2"], "test")
        XCTAssertTrue(
            stringEncodedMimeType.description == "text/plain; test=test; test2=test"
            || stringEncodedMimeType.description == "text/plain; test2=test; test=test"
        )
        
        let simpleEtringEncodedMimeType = try XCTUnwrap(HTTPMediaType("text/plain"))
        XCTAssertEqual(simpleEtringEncodedMimeType.type, "text")
        XCTAssertEqual(simpleEtringEncodedMimeType.subtype, "plain")
        XCTAssertEqual(simpleEtringEncodedMimeType.description, "text/plain")
        
        let customMimeType = HTTPMediaType(type: "video", subtype: "mp4")
        XCTAssertEqual(customMimeType.type, "video")
        XCTAssertEqual(customMimeType.subtype, "mp4")
        XCTAssertEqual(customMimeType.parameters, [:])
        
        XCTAssertNil(HTTPMediaType("text"))
        XCTAssertEqual(HTTPMediaType("text/plain;parameter"), HTTPMediaType(type: "text", subtype: "plain"))
        XCTAssertEqual(HTTPMediaType("text/markdown"), HTTPMediaType(type: "text", subtype: "markdown"))
        XCTAssertEqual(HTTPMediaType("application/widget"), HTTPMediaType(type: "application", subtype: "widget"))
        XCTAssertEqual(HTTPMediaType("image/tiff"), HTTPMediaType(type: "image", subtype: "tiff"))
        XCTAssertEqual(HTTPMediaType("video/mp4"), HTTPMediaType(type: "video", subtype: "mp4"))
        XCTAssertEqual(
            try XCTUnwrap(HTTPMediaType("text/plain;test=test;test2=test")),
            try XCTUnwrap(HTTPMediaType("text/plain; test=test; test2=test"))
        )
    }
    
    func testMIMEDecoding() throws {
        let validMIMEJSON =
            """
            {
              "type" : "text",
              "subtype" : "plain",
              "parameters" : {
            
              }
            }
            """
        
        let decoder = JSONDecoder()
        let mimeType = try XCTUnwrap(decoder.decode(HTTPMediaType.self, from: Data(validMIMEJSON.utf8)))
        
        XCTAssertEqual(mimeType.type, "text")
        XCTAssertEqual(mimeType.subtype, "plain")
        XCTAssertTrue(mimeType.parameters.isEmpty)
        
        
        let inValidMIMEJSON =
            """
            {
              "type" : "myFancyType",
              "subtypes" : "plain",
              "parameters" : {
            
              }
            }
            """
        
        try XCTAssertThrowsError(decoder.decode(HTTPMediaType.self, from: Data(inValidMIMEJSON.utf8)))
    }
}
