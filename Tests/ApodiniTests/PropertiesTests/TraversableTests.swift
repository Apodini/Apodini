//
//  TraversableTests.swift
//  
//
//  Created by Max Obermeier on 15.12.20.
//

@testable import Apodini
import XCTest


final class TraversableTests: ApodiniTests {
    // swiftlint:disable identifier_name type_name
    @propertyWrapper
    struct Param<T>: Apodini.Property, InstanceCodable {
        var _value: T?
        
        var wrappedValue: T? {
            _value
        }
    }
    
    struct Element: Codable {
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
    
    struct Container {
        let wrapperProperties: Properties = [
            "theName": Param<String>()
        ]
        
        let theNameProperties = Properties(wrappedValue: [
            "notTheName": Param<String?>()
        ], namingStrategy: { names in names[names.count - 2] })
        
        struct Wrapper: DynamicProperty {
            let theName = Param<String??>()
        }
        
        struct TransparentWrapper: DynamicProperty {
            let notTheName = Param<String???>()
            
            func namingStrategy(_ names: [String]) -> String? {
                names[names.count - 2]
            }
        }
        
        let wrapperDynamicProperty = Wrapper()
        
        let theNameDynamicProperty = TransparentWrapper()
    }
    
    func testNamingStragety() throws {
        var container = Container()
        
        exposedExecute({(_: Param<String>, name: String) in
            XCTAssertEqual("theName", name)
        }, on: container)
        exposedApply({(_: inout Param<String>, name: String) in
            XCTAssertEqual("theName", name)
        }, to: &container)
        
        exposedExecute({(_: Param<String?>, name: String) in
            XCTAssertEqual("theNameProperties", name)
        }, on: container)
        exposedApply({(_: inout Param<String?>, name: String) in
            XCTAssertEqual("theNameProperties", name)
        }, to: &container)
        
        exposedExecute({(_: Param<String??>, name: String) in
            XCTAssertEqual("theName", name)
        }, on: container)
        exposedApply({(_: inout Param<String??>, name: String) in
            XCTAssertEqual("theName", name)
        }, to: &container)
        
        exposedExecute({(_: Param<String???>, name: String) in
            XCTAssertEqual("theNameDynamicProperty", name)
        }, on: container)
        exposedApply({(_: inout Param<String???>, name: String) in
            XCTAssertEqual("theNameDynamicProperty", name)
        }, to: &container)
    }
    
//    func testInstanceCoder() throws {
//        let element = Element()
//
//        print(element)
//
//        let mutator = Mutator()
//
//        try element.encode(to: mutator)
//
//        let decoded1 = try Element(from: mutator)
//
//        print(decoded1)
//
//        mutator.reset()
//
//        let decoded2 = try Element(from: mutator)
//
//        print(decoded2)
//    }
}
