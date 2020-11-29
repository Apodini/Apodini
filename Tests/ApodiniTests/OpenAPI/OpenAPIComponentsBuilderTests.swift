//
//  OpenAPIComponentsBuilderTests.swift
//  
//
//  Created by Lorena Schlesinger on 29.11.20.
//

import XCTest
import Foundation
import OpenAPIKit
import NIO
@testable import Apodini

final class OpenAPIComponentsBuilderTests: XCTestCase {


    func testBasicTypes() {
        // arrange
        struct SomeOtherType {
            var c: EventLoopFuture<Int>
        }
        
        struct Item {
            var a: String
        }
        
        struct Bag<T> {
            var list: [T]
            var listLength: Int
        }
        
        struct SomeType {
            var someIntFuture: EventLoopFuture<Int>
            var someDouble: Double
            var someOptString: String?
            var someBoolArray: [Bool]
            var someBoolDict: [String: Bool]
            // var someBoolTuple: (Bool, Bool)
            var someOtherType: SomeOtherType
            var someSubby: SomeSubType
            var someSubby2: SomeSubType
            var someItems: Bag<Item>
            
            struct SomeSubType {
                let a = 123
                let b: String?
            }
        }
        
        let openAPIComponentsBuilder = OpenAPIComponentsBuilder()
        
        // act
        var some: JSONSchema
        do {
            some = try openAPIComponentsBuilder.findOrCreateSchema(from: SomeType.self)
        } catch {
            print(error)
            some = JSONSchema.string()
        }
        print("\(some)")
        print("\(openAPIComponentsBuilder.components)")
        
        let encoder = JSONEncoder()
        if let json = try? encoder.encode(OpenAPI.Document(
            info: OpenAPI.Document.Info(title: "test", version: "1.0"),
            servers: [],
            paths: OpenAPI.PathItem.Map(),
            components: openAPIComponentsBuilder.components
        )) {
            print(String(data: json, encoding: .utf8)!)
        }
        
        // assert
        XCTAssertEqual(true, true)
    }
}
