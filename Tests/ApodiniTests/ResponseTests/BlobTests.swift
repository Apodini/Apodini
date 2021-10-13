//
//  BlobTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import XCTApodini
import XCTApodiniHTTP
@testable import ApodiniREST
@testable import Apodini
@testable import ApodiniOpenAPI
import Vapor


final class BlobTests: XCTApodiniHTTPTest {
    func testBlobResponseHandler() throws {
        struct BlobResponseHandler: Handler {
            @Parameter var mimeType: MimeType
            
            func handle() -> Blob {
                Blob(Data(), type: mimeType)
            }
        }

        let mimeTypes = [
            MimeType.text(.html, parameters: ["Test": "Test"]),
            MimeType.application(.json),
            MimeType.image(.gif)
        ]
        
        for mimeType in mimeTypes {
            try XCTCheckHandler(BlobResponseHandler()) {
                MockRequest(expectation: Blob(Data(), type: mimeType)) {
                    NamedParameter("mimeType", value: mimeType)
                }
            }
        }
    }
    
    func testBlobRESTEndpointHandler() throws {
        struct BlobResponseHandler: Handler {
            @Parameter var name: String
            @Parameter var mimeType: MimeType
            
            func handle() -> Apodini.Response<Blob> {
                .send(Blob(Data(name.utf8), type: mimeType), status: .ok)
            }
        }
        
        func makeRequest(blobContent: String, mimeType: MimeType) throws {
            let path = "https://ase.in.tum.de/schmiedmayer?name=\(blobContent)"
            let body = ByteBuffer(data: try JSONEncoder().encode(mimeType))
            
            try XCTHTTPCheck(BlobResponseHandler()) {
                HTTPCheck(HTTPRequest(path: path, body:body)) { response in
                    XCTAssertEqual(response.body.getString(at: response.body.readerIndex, length: response.body.readableBytes), blobContent)
                }
            }
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
        
        XCTAssert(encodedBlob.contains(#""byteBuffer" : "UGF1bA==""#))
        XCTAssert(encodedBlob.contains(#""type" : "text""#))
        XCTAssert(encodedBlob.contains(#""subtype" : "plain""#))
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
        let mimeType = try XCTUnwrap(decoder.decode(MimeType.self, from: Data(validMIMEJSON.utf8)))
        
        XCTAssertEqual(mimeType.type, "text")
        XCTAssertEqual(mimeType.subtype, "plain")
        XCTAssertTrue(mimeType.parameters.isEmpty)
        
        
        let inValidMIMEJSON =
            """
            {
              "type" : "myFancyType",
              "subtype" : "plain",
              "parameters" : {
            
              }
            }
            """
        
        try XCTAssertThrowsError(decoder.decode(MimeType.self, from: Data(inValidMIMEJSON.utf8)))
    }
}
