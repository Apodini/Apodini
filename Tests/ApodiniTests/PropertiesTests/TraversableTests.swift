//
//  TraversableTests.swift
//  
//
//  Created by Max Obermeier on 15.12.20.
//

@testable import Apodini
import XCTest
import ApodiniUtils


final class TraversableTests: ApodiniTests {
    // swiftlint:disable identifier_name type_name
    @propertyWrapper
    struct Param<T>: Apodini.Property, InstanceCodable {
        var _value: T?
        
        var wrappedValue: T? {
            _value
        }
    }
    
    struct Element: Codable, Equatable {
        @Param var a: String?
        @BCD var bcd: String
        var efg = Properties()
            .with(Param<String>(), named: "e")
            .with(Properties()
                    .with(Param<String>(), named: "f")
                    .with(G(), named: "g"), named: "fgWrapper")
        
        var allParameters: String {
            let e: Param<String>? = efg.e
            let fgWrapper: Properties? = efg.fgWrapper
            
            let f: Param<String>? = fgWrapper?.f
            
            let g: G? = fgWrapper?.g
            
            return "\(a ?? "")\(bcd)\(e?.wrappedValue ?? "")\(f?.wrappedValue ?? "")\(g?.wrappedValue ?? "")"
        }
    }
    
    @propertyWrapper
    struct BCD: DynamicProperty, Equatable {
        @Param var b: String?
        @Properties var properties: [String: Apodini.Property]
        @D var d: String
        
        init() {
            self._properties = Properties().with(Param<String>(), named: "c")
        }
        
        var wrappedValue: String {
            let c = _properties.typed(Param<String>.self)["c"]
            return "\(b ?? "")\(c?.wrappedValue ?? "")\(d)"
        }
    }
    
    @propertyWrapper
    struct D: DynamicProperty, Equatable {
        @Param var d: String?
        
        var wrappedValue: String {
            d ?? ""
        }
    }
    
    @propertyWrapper
    struct G: DynamicProperty, Equatable {
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
        var wrapper = Properties().with(Param<String>(), named: "a")
        
        exposedApply({(target: inout Param<String>, name: String) in
            target._value = name.trimmingCharacters(in: ["_"])
        }, to: &wrapper)
        
        let aParam: Param<String>? = wrapper.a
        
        XCTAssertEqual(aParam?.wrappedValue, "a")
    }
    
    func testExecuteOnProperties() throws {
        var names: [String] = []
        
        let wrapper = Properties().with(Param<String>(), named: "a")
        
        exposedExecute({(_: Param<String>, name: String) in
            names.append(name.trimmingCharacters(in: ["_"]))
        }, on: wrapper)
        
        XCTAssertEqual(names.sorted().joined(), "a")
    }
    
    struct Container {
        let wrapperProperties = Properties().with(Param<String>(), named: "theName")
        
        let theNameProperties = Properties(namingStrategy: { names in names[names.count - 2] })
            .with(Param<String?>(), named: "notTheName")
        
        struct Wrapper: DynamicProperty {
            var theName = Param<String??>()
        }
        
        struct TransparentWrapper: DynamicProperty {
            var notTheName = Param<String???>()
            
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
    
    func testInstanceCoder() throws {
        let element = Element()

        print(element)

        let mutator = Coder()

        try element.encode(to: mutator)
        
        print(mutator.baseStore.debugDescription)
        
        let decoded1 = try Element(from: mutator)

        print(decoded1)
        
        XCTAssertEqual(decoded1, element)

        let decoded2 = try Element(from: mutator)

        print(decoded2)
        
        XCTAssertEqual(decoded2, element)
    }
}

extension Properties: Equatable {
    public static func == (lhs: Properties, rhs: Properties) -> Bool {
        if lhs.elements.keys != rhs.elements.keys || rhs.codingInfo.keys != rhs.codingInfo.keys {
            return false
        }
        
        for (key, elem) in lhs.elements {
            if AnyEquatable.compare(elem, rhs.elements[key]!) != .equal {
                return false
            }
        }
        return true
    }
}

extension TraversableTests.Param: Equatable where T: Equatable {
    static func == (lhs: TraversableTests.Param<T>, rhs: TraversableTests.Param<T>) -> Bool {
        lhs._value == rhs._value
    }
}
