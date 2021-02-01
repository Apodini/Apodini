import Foundation
import XCTest
import NIO
import Vapor
@testable import Apodini
@testable import ApodiniDatabase
@testable import ApodiniREST

final class DownloaderTests: FileHandlerTests {
    func testSingleDownloader() throws {
        let uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/"))
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        let request = MockRequest.createRequest(on: uploader, running: app.eventLoopGroup.next(), queuedParameters: file)
        let response = try request.enterRequestContext(with: uploader, executing: { component in
            // swiftlint:disable force_try
            try! component.handle()
        })
        .wait()
        XCTAssert(response == file.filename)
        
        let downloader = SingleDownloader(DownloadConfiguration(.default))
        let endpoint = downloader.mockEndpoint()
        
        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)
        
        let uri = URI("http://example.de/test/fileName")
        let downloadRequest = Vapor.Request(
            application: app.vapor.app,
            method: .GET,
            url: uri,
            on: app.eventLoopGroup.next()
        )
        
        let parameter = try FileUtilities.pathParameter(for: downloader)
        
        downloadRequest.parameters.set("\(parameter.id)", to: "Testfile.jpeg")
        
        let result = try context.handle(request: downloadRequest).wait()
        guard case let .final(responseValue) = result.typed(ApodiniDatabase.File.self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        XCTAssert(file.filename == responseValue.filename)
        XCTAssert(file.data == responseValue.data)
    }
    
    func testMultipleDownloader() throws {
        // Upload first file
        var uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/"))
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        var request = MockRequest.createRequest(on: uploader, running: app.eventLoopGroup.next(), queuedParameters: file)
        var response = try request.enterRequestContext(with: uploader, executing: { component in
            // swiftlint:disable force_try
            try! component.handle()
        })
        .wait()
        XCTAssert(response == file.filename)
        
        // Upload second file
        uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/MoreMisc/"))
        let file2 = File(data: data, filename: "Testfile123.jpeg")
        
        request = MockRequest.createRequest(on: uploader, running: app.eventLoopGroup.next(), queuedParameters: file2)
        response = try request.enterRequestContext(with: uploader, executing: { component in
            // swiftlint:disable force_try
            try! component.handle()
        })
        .wait()
        XCTAssert(response == file2.filename)
        
        let downloader = MultipleDownloader(DownloadConfiguration(.default))
        let endpoint = downloader.mockEndpoint()
        
        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)
        
        let uri = URI("http://example.de/test/fileName")
        let downloadRequest = Vapor.Request(
            application: app.vapor.app,
            method: .GET,
            url: uri,
            on: app.eventLoopGroup.next()
        )
        
        let parameter = try FileUtilities.pathParameter(for: downloader)
        
        downloadRequest.parameters.set("\(parameter.id)", to: ".jpeg")
        
        let result = try context.handle(request: downloadRequest).wait()
        guard case let .final(responseValue) = result.typed([ApodiniDatabase.File].self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        XCTAssert(responseValue.count == 2)
        XCTAssert(responseValue[0] == file || responseValue[0] == file2)
        XCTAssert(responseValue[1] == file || responseValue[1] == file2)
    }
}
