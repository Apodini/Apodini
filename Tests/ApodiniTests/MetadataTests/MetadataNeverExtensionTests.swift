//
// Created by Andreas Bauer on 22.05.21.
//

import XCTApodini

final class MetadataNeverExtensionTests: ApodiniTests {
    func testNeverContextKey() {
        XCTAssertRuntimeFailure(Never.defaultValue)
    }
}
