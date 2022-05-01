//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import XCTest
import ApodiniUtils


class FileManagerUtilsTests: XCTestCase {
    private let FM = FileManager.default
    
    func testFilePermissionsParsing() {
        XCTAssertEqual(POSIXPermissions("r---w---x"), .init(owner: .read, group: .write, world: .execute))
        //XCTAssertEqual(POSIXPermissions(owner: .write, group: [], world: <#T##POSIXPermissions.PermissionValues#>), <#T##expression2: Equatable##Equatable#>)
        XCTAssertEqual(
            POSIXPermissions(owner: [.read, .write, .execute], group: [.read, .write, .execute], world: [.read, .write, .execute]).stringRepresentation,
            "rwxrwxrwx"
        )
        XCTAssertEqual(POSIXPermissions(rawValue: 0o240).stringRepresentation, "-w-r-----")
        XCTAssertEqual(POSIXPermissions(owner: [], group: [], world: []).rawValue, 0o000)
        XCTAssertEqual(POSIXPermissions(owner: .rwx, group: .rwx, world: .rwx).rawValue, 0o777)
    }
    
    
    func testReadFilePermissions() throws {
        let tmpUrl = FM.getTemporaryFileUrl(fileExtension: "txt")
        try Data().write(to: tmpUrl)
        XCTAssertEqual(try FM.permissions(ofItemAt: tmpUrl).stringRepresentation, "rw-r--r--")
        try FM.setPermissions("rwx------", forItemAt: tmpUrl)
        XCTAssertEqual(try FM.permissions(ofItemAt: tmpUrl).stringRepresentation, "rwx------")
    }
}
