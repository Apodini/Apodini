import Foundation
import XCTest
@testable import ApodiniDatabase


fileprivate extension TypeContainer {
    var debugDescription: String {
        self.typed()
            .debugDescription
            .replacingOccurrences(of: "Optional(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "\"", with: "")
    }
}


final class TypeContainerTests: ApodiniTests {
    func testTypeContainer() throws {
        func testDebugDescription<T: Codable>(_ element: T, expectedDescription: String) throws {
            let typeContainer = TypeContainer(with: element)
            XCTAssert(typeContainer.typed() is T)
            XCTAssertEqual(typeContainer.debugDescription, expectedDescription)
        }
        
        try testDebugDescription(Int(-2), expectedDescription: String(-2))
        try testDebugDescription(Int8(-2), expectedDescription: String(-2))
        try testDebugDescription(Int16(-2), expectedDescription: String(-2))
        try testDebugDescription(Int32(-2), expectedDescription: String(-2))
        try testDebugDescription(Int64(-2), expectedDescription: String(-2))
        try testDebugDescription(UInt(2), expectedDescription: String(2))
        try testDebugDescription(UInt8(2), expectedDescription: String(2))
        try testDebugDescription(UInt16(2), expectedDescription: String(2))
        try testDebugDescription(UInt32(2), expectedDescription: String(2))
        try testDebugDescription(UInt64(2), expectedDescription: String(2))
        try testDebugDescription(Double(2.2), expectedDescription: String(2.2))
        try testDebugDescription(Float(2.2), expectedDescription: String(2.2))
        
        let uuid = UUID()
        try testDebugDescription(uuid, expectedDescription: uuid.uuidString)
        
        try testDebugDescription(true, expectedDescription: "true")
        
        try testDebugDescription("HelloWorld", expectedDescription: "HelloWorld")
    }
    
    func testTypeContainerIntegerCoding() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        func endcodeAndDecode<T: Codable & Equatable>(_ element: T) throws {
            let typeContainer = TypeContainer(with: element)
            // let encodedContainer = try encoder.encode(typeContainer)
            // let decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
            //XCTAssert(typeContainer.typed() is T)
            //XCTAssertEqual(typeContainer.typed().wrapped as? T, element)
            XCTFail()
        }
        
        try endcodeAndDecode(Int(-2))
        try endcodeAndDecode(Int8(-2))
        try endcodeAndDecode(Int16(-2))
        try endcodeAndDecode(Int32(-2))
        try endcodeAndDecode(Int64(-2))
        try endcodeAndDecode(UInt(2))
        try endcodeAndDecode(UInt8(2))
        try endcodeAndDecode(UInt16(2))
        try endcodeAndDecode(UInt32(2))
        try endcodeAndDecode(UInt64(2))
        try endcodeAndDecode(UUID())
        try endcodeAndDecode(true)
        try endcodeAndDecode("HelloWorld")
    }
}
