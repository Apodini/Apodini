//
//  TraversableTests.swift
//  
//
//  Created by Max Obermeier on 15.12.20.
//

import XCTest
import NIO
import Vapor
import Fluent
@testable import Apodini


final class TraversableTests: ApodiniTests {
    // swiftlint:disable identifier_name type_name
    @propertyWrapper
    struct Param<T>: Apodini.Property {
        var _value: T?
        
        var wrappedValue: T? {
            _value
        }
    }
    
    struct Element {
        @Param var a: String?
        @BCD var bcd: String
        var efg: Properties = [
            "e": Param<String>(),
            "fgWrapper": Properties(wrappedValue: [
                "f": Param<String>(),
                "g": G()
            ])
        ]
        
        var allParameters: String {
            let e: Param<String>? = efg.e
            let fgWrapper: Properties? = efg.fgWrapper
            
            let f: Param<String>? = fgWrapper?.f
            
            let g: G? = fgWrapper?.g
            
            return "\(a ?? "")\(bcd)\(e?.wrappedValue ?? "")\(f?.wrappedValue ?? "")\(g?.wrappedValue ?? "")"
        }
    }
    
    @propertyWrapper
    struct BCD: DynamicProperty {
        @Param var b: String?
        @Properties var properties: [String: Apodini.Property]
        @D var d: String
        
        init() {
            self._properties = ["c": Param<String>()]
        }
        
        var wrappedValue: String {
            let c = _properties.typed(Param<String>.self)["c"]
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
            g ?? ""
        }
    }
    // swiftlint:enable identifier_name type_name

    
    func testApply() throws {
        var element = Element()
        exposedApply({(target: inout Param<String>, name: String) in
            target._value = name.trimmingCharacters(in: ["_"])
        }, to: &element)
        
        XCTAssertEqual(element.allParameters, "abcdefg")
    }
    
    func testApplyWithoutName() throws {
        var element = Element()
        exposedApply({(target: inout Param<String>) in
            target._value = "."
        }, to: &element)
        
        XCTAssertEqual(element.allParameters, ".......")
    }
    
    func testExecute() throws {
        var names: [String] = []
        let element = Element()
        exposedExecute({(_: Param<String>, name: String) in
            names.append(name.trimmingCharacters(in: ["_"]))
        }, on: element)
        
        // as Properties is map-based we cannot rely on a static order
        XCTAssertEqual(names.sorted().joined(), "abcdefg")
    }
    
    func testExecuteWithoutName() throws {
        var count: Int = 0
        let element = Element()
        exposedExecute({(_: Param<String>) in
            count += 1
        }, on: element)
        
        XCTAssertEqual(count, 7)
    }
    
    func testApplyOnProperties() throws {
        var wrapper: Properties = [
            "a": Param<String>()
        ]
        
        exposedApply({(target: inout Param<String>, name: String) in
            target._value = name.trimmingCharacters(in: ["_"])
        }, to: &wrapper)
        
        let aParam: Param<String>? = wrapper.a
        
        XCTAssertEqual(aParam?.wrappedValue, "a")
    }
    
    func testExecuteOnProperties() throws {
        var names: [String] = []
        
        let wrapper: Properties = [
            "a": Param<String>()
        ]
        
        exposedExecute({(_: Param<String>, name: String) in
            names.append(name.trimmingCharacters(in: ["_"]))
        }, on: wrapper)
        
        XCTAssertEqual(names.sorted().joined(), "a")
    }
}
