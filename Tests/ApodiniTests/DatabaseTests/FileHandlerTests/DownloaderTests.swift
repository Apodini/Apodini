//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
@testable import ApodiniDatabase
@testable import ApodiniREST
import XCTApodini
import ApodiniNetworking


final class DownloaderTests: FileHandlerTests {
    func testSingleDownloader() throws {
        let uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/"))
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        let response = try XCTUnwrap(mockQuery(handler: uploader, value: String.self, app: app, queued: file))
        XCTAssert(response == file.filename)
        
        let downloader = SingleDownloader(DownloadConfiguration(.default))
        let endpoint = downloader.mockEndpoint(app: app)
        
        let exporter = RESTInterfaceExporter(app)
        let context = endpoint.createConnectionContext(for: exporter)
        
//        let uri = URI("http://example.de/test/fileName")
//        let downloadRequest = Vapor.Request(
//            application: app.vapor.app,
//            method: .GET,
//            url: uri,
//            on: app.eventLoopGroup.next()
//        )
        
        let url: URI = "http://example.de/test/fileName"
        let downloadRequest = HTTPRequest(method: .GET, url: url, eventLoop: app.eventLoopGroup.next())
        
        let parameter = try FileUtilities.pathParameter(for: downloader)
        
        downloadRequest.setParameter(for: "\(parameter.id)", to: "Testfile.jpeg")
        
        try XCTCheckResponse(
            context.handle(request: downloadRequest),
            content: file,
            connectionEffect: .close
        )
    }
    
    func testMultipleDownloader() throws {
        // Upload first file
        var uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/"))
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        var response = try XCTUnwrap(mockQuery(handler: uploader, value: String.self, app: app, queued: file))
        XCTAssert(response == file.filename)
        
        // Upload second file
        uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/MoreMisc/"))
        let file2 = File(data: data, filename: "Testfile123.jpeg")
        
        response = try XCTUnwrap(mockQuery(handler: uploader, value: String.self, app: app, queued: file2))
        XCTAssert(response == file2.filename)
        
        let downloader = MultipleDownloader(DownloadConfiguration(.default))
        let endpoint = downloader.mockEndpoint(app: app)
        
        let exporter = RESTInterfaceExporter(app)
        let context = endpoint.createConnectionContext(for: exporter)
        
//        let uri = URI("http://example.de/test/fileName")
//        let downloadRequest = Vapor.Request(
//            application: app.vapor.app,
//            method: .GET,
//            url: uri,
//            on: app.eventLoopGroup.next()
//        )
        let url: URI = "http://example.de/test/fileName"
        let downloadRequest = HTTPRequest(method: .GET, url: url, eventLoop: app.eventLoopGroup.next())
        
        let parameter = try FileUtilities.pathParameter(for: downloader)
        
        downloadRequest.setParameter(for: "\(parameter.id)", to: ".jpeg")
        
        let responseValue = try XCTUnwrap(
            try context.handle(request: downloadRequest)
                .wait()
                .typed([ApodiniDatabase.File].self)?
                .content
        )

        XCTAssert(responseValue.count == 2)
        XCTAssert(responseValue[0] == file || responseValue[0] == file2)
        XCTAssert(responseValue[1] == file || responseValue[1] == file2)
    }
}
