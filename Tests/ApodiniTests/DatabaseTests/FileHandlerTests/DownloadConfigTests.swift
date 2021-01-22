import Foundation
import XCTest
import NIO
import Vapor
@testable import Apodini
@testable import ApodiniDatabase

final class DownloadConfigTests: ApodiniTests {
    func testDownloadConfigInfo() throws {
        //Upload file
        let uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/"))
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        let request = MockRequest.createRequest(on: uploader, running: app.eventLoopGroup.next(), queuedParameters: file)
        let response = try request.enterRequestContext(with: uploader, executing: { component in
            try! component.handle()
        })
        .wait()
        XCTAssert(response == file.filename)
        
        
        let directory = Environment(\.directory).wrappedValue
        let config = DownloadConfiguration(.default)
        let fileInfo = try config.retrieveFileInfo(file.filename, in: directory)
        
        XCTAssertNotNil(fileInfo)
        XCTAssert(fileInfo!.fileName == file.filename)
        XCTAssert(fileInfo!.path == directory.publicDirectory + "Misc/Testfile.jpeg")
        let foundData = try Data(contentsOf: URL(fileURLWithPath: fileInfo!.path))
        XCTAssert(fileInfo!.readableBytes == foundData.count)
    }
    
    func testDownloadConfigInfos() throws {
        // Upload first file
        var uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/"))
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        var request = MockRequest.createRequest(on: uploader, running: app.eventLoopGroup.next(), queuedParameters: file)
        var response = try request.enterRequestContext(with: uploader, executing: { component in
            try! component.handle()
        })
        .wait()
        XCTAssert(response == file.filename)
        
        // Upload second file
        uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/MoreMisc/"))
        let file2 = File(data: data, filename: "Testfile123.jpeg")
        
        request = MockRequest.createRequest(on: uploader, running: app.eventLoopGroup.next(), queuedParameters: file2)
        response = try request.enterRequestContext(with: uploader, executing: { component in
            try! component.handle()
        })
        .wait()
        XCTAssert(response == file2.filename)
        
        let directory = Environment(\.directory).wrappedValue
        let config = DownloadConfiguration(.default)
        let fileInfos = try config.retrieveFileInfos(".jpeg", in: directory)
        
        XCTAssertNotNil(fileInfos)
        let infos = try XCTUnwrap(fileInfos)
        XCTAssert(infos[0].fileName == file.filename || infos[0].fileName == file2.filename)
        XCTAssert(infos[1].fileName == file.filename || infos[1].fileName == file2.filename)
    }

}
