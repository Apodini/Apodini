import XCTest
import ApodiniUtils


@propertyWrapper
class ManagedLifetimeCString {
    private var storage: UnsafeMutablePointer<CChar>
    
    init(wrappedValue ptr: UnsafeMutablePointer<CChar>) {
        storage = ptr
    }
    
    deinit {
        print("DEINIT \(String(cString: storage))")
        free(storage)
    }
    
    var wrappedValue: UnsafeMutablePointer<CChar> {
        storage
    }
}



class ApodiniUtilsTests: XCTestCase {
    func testStringWhitespaceTrimming() {
        XCTAssertEqual("Hello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual(" Hello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual(" Hello World".trimmingTrailingWhitespace(), " Hello World")
        XCTAssertEqual("\tHello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual(" \t Hello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual("Hello World\t".trimmingTrailingWhitespace(), "Hello World")
        XCTAssertEqual("Hello\tWorld".trimmingLeadingWhitespace(), "Hello\tWorld")
        XCTAssertEqual("Hello\tWorld".trimmingTrailingWhitespace(), "Hello\tWorld")
        XCTAssertEqual("\tHello World\t".trimmingLeadingAndTrailingWhitespace(), "Hello World")
    }
    
    
    func testCreateStringFromInt8Tuple() throws {
        @ManagedLifetimeCString var cString = strdup("abcd")
        
        XCTAssertEqual("abcd", try XCTUnwrap(String.createFromInt8Tuple(
            (cString[0], cString[1], cString[2], cString[3])
        )))
    }
}
