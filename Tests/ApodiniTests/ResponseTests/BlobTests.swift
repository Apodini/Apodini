//
//  BlobTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import XCTApodini
@testable import ApodiniREST
@testable import Apodini
@testable import ApodiniOpenAPI
import Vapor


final class BlobTests: ApodiniTests {
    func testBlobResponseHandler() throws {
        struct BlobResponseHandler: Handler {
            @Parameter var mimeType: MimeType
            
            func handle() -> Blob {
                Blob(Data(), type: mimeType)
            }
        }
        
        let handler = BlobResponseHandler().inject(app: app)
        let endpoint = handler.mockEndpoint()

        let mimeTypes = [
            MimeType.text(.html, parameters: ["Test": "Test"]),
            MimeType.application(.json),
            MimeType.image(.gif)
        ]
        
        let exporter = MockExporter<String>(queued: mimeTypes[0], mimeTypes[1], mimeTypes[2])
        let context = endpoint.createConnectionContext(for: exporter)

        try XCTCheckResponse(
            context.handle(request: "", eventLoop: app.eventLoopGroup.next()),
            content: Blob(Data(), type: mimeTypes[0]),
            connectionEffect: .close
        )
        
        try XCTCheckResponse(
            context.handle(request: "", eventLoop: app.eventLoopGroup.next()),
            content: Blob(Data(), type: mimeTypes[1]),
            connectionEffect: .close
        )
        
        try XCTCheckResponse(
            context.handle(request: "", eventLoop: app.eventLoopGroup.next()),
            content: Blob(Data(), type: mimeTypes[2]),
            connectionEffect: .close
        )
    }
    
    func testBlobRESTEndpointHandler() throws {
        struct BlobResponseHandler: Handler {
            @Parameter var name: String
            @Parameter var mimeType: MimeType
            
            func handle() -> Blob {
                Blob(Data(name.utf8), type: mimeType)
            }
        }
        
        let handler = BlobResponseHandler()
        let endpoint = handler.mockEndpoint(app: app)
        
        let exporter = RESTInterfaceExporter(app)
        let endpointHandler = RESTEndpointHandler(with: RESTConfiguration(app.vapor.app.http.server.configuration), for: endpoint, on: exporter)
        
        
        func makeRequest(blobContent: String, mimeType: MimeType) throws {
            let request = Vapor.Request(
                application: app.vapor.app,
                method: .GET,
                url: URI("https://ase.in.tum.de/schmiedmayer?name=\(blobContent)"),
                collectedBody: ByteBuffer(data: try JSONEncoder().encode(mimeType)),
                on: app.eventLoopGroup.next()
            )
            
            let response = try endpointHandler.handleRequest(request: request).wait()
            let byteBuffer = try XCTUnwrap(response.body.buffer)
                
            XCTAssertEqual(byteBuffer.getString(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes), blobContent)
        }

        try makeRequest(blobContent: "Nadine", mimeType: .application(.json))
        try makeRequest(blobContent: "Paul", mimeType: .text(.plain, parameters: ["User": "Paul"]))
        try makeRequest(blobContent: "Bernd", mimeType: .image(.gif))
    }
    
    func testBlobResponseHandlerWithOpenAPIExporter() throws {
        let blobSchema = try OpenAPIComponentsObjectBuilder().buildResponse(for: Blob.self)
        XCTAssertEqual(.string(format: .binary, required: true), blobSchema)
    }
    
    func testBlobEncoding() throws {
        let blob = Blob(Data("Paul".utf8), type: .text(.plain))
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedBlob = try XCTUnwrap(String(data: try encoder.encode(blob), encoding: .utf8))
        
        XCTAssertEqual(
            encodedBlob,
            """
            {
              "type" : {
                "type" : "text",
                "subtype" : "plain",
                "parameters" : {
            
                }
              },
              "byteBuffer" : "UGF1bA=="
            }
            """
        )
    }
}
