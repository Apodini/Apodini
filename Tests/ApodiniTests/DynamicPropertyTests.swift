//
//  DynamicPropertyTests.swift
//  
//
//  Created by Max Obermeier on 15.12.20.
//

import XCTest
import NIO
import Vapor
import Fluent
@testable import Apodini


final class DynamicPropertyTests: ApodiniTests {
    
    @propertyWrapper
    struct Param<T> {
        var _value: T? = nil
        
        var wrappedValue: T? {
            return _value
        }
    }
    
    struct Element {
        @Param var a: String?
        @BCD var bcd: String
        var efg: Dynamics = [
            "e": Param<String>(),
            "fgWrapper": Dynamics([
                "f":  Param<String>(),
                "g": G()
            ])
        ]
        
        var allParameters: String {
            let e: Param<String>? = efg["e"]
            let fgWrapper: Dynamics? = efg["fgWrapper"]
            
            let f: Param<String>? = fgWrapper?["f"]
            
            let g: G? = fgWrapper?["g"]
            
            return "\(a ?? "")\(bcd)\(e?.wrappedValue ?? "")\(f?.wrappedValue ?? "")\(g?.wrappedValue ?? "")"
        }
    }
    
    @propertyWrapper
    struct BCD: DynamicProperty {
        @Param var b: String?
        var dynamics: Dynamics = ["c": Param<String>()]
        @D var d: String
        
        var wrappedValue: String {
            let c: Param<String>? = dynamics["c"]
            return "\(b ?? "")\(c?.wrappedValue ?? "")\(d)"
        }
    }
    
    @propertyWrapper
    struct D: DynamicProperty {
        @Param var d: String?
        
        var wrappedValue: String {
            d ?? ""
        }
    }
    
    @propertyWrapper
    struct G: DynamicProperty {
        @Param var g: String?
        
        var wrappedValue: String {
            return g ?? ""
        }
    }

    
    func testApply() throws {
        var element = Element()
        apply({(target: inout Param<String>, name: String) in
            target._value = name.trimmingCharacters(in: ["_"])
        }, to: &element)
        
        XCTAssertEqual(element.allParameters, "abcdefg")
    }
    
    func testApplyWithoutName() throws {
        var element = Element()
        apply({(target: inout Param<String>) in
            target._value = "."
        }, to: &element)
        
        XCTAssertEqual(element.allParameters, ".......")
    }
    
    func testExecute() throws {
        var names: [String] = []
        let element = Element()
        execute({(_: Param<String>, name: String) in
            names.append(name.trimmingCharacters(in: ["_"]))
        }, on: element)
        
        XCTAssertEqual(names.joined(separator: ""), "abcdefg")
    }
    
    func testExecuteWithoutName() throws {
        var count: Int = 0
        let element = Element()
        execute({(_: Param<String>) in
            count += 1
        }, on: element)
        
        XCTAssertEqual(count, 7)
    }
}
