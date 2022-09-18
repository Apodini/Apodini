//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import Apodini
@testable import ApodiniAudit
@testable import ApodiniREST

final class EncourageETagsTests: ApodiniTests {
    func testETagSuggestion() throws {
        try assertOneFinding()
    }
}

struct BlobWebService: WebService {
    var content: some Component {
        BlobTypeHandler().endpointName("Blob")
    }
}

struct BlobTypeHandler: Handler {
    func handle() -> Blob {
        Blob(ByteBuffer())
    }
}

func getAudit() throws -> Audit {
    let webService = BlobWebService()
    let app = Application()
    let endpoint = try getEndpointFromWebService(webService, app, "Blob")
    return EncourageETags().check(for: endpoint, app)
}

func assertOneFinding() throws {
    let audit = try getAudit()
    XCTAssertEqual(audit.findings.count, 1)
    guard let finding = audit.findings[0] as? ETagsFinding else {
        XCTFail("Could not typecast Finding")
        return
    }
    guard finding == .cacheableBlob else {
        XCTFail(".cacheableBlob not found!")
        return
    }
}
