//
//  File.swift
//  
//
//  Created by Eldi Cano on 12.04.21.
//

@testable import ApodiniTypeDescriptor
import XCTest


class TypeDescriptorTests: XCTestCase {
    struct Car: Encodable {
        let plateNumber: Int?
        let color: String
    }
    
    struct User: Encodable {
        private enum CodingKeys: String, CodingKey {
            case id, name = "_name", car
        }
        
        let id: Int?
        let name: String
        let car: Car?
    }
    
    
    struct Student: Encodable {
        let id: Int?
        let users: [String:User]
        let grades: [Float]
        let name: String?
        let surname: String
    }
    
    func testStudentTypeDescriptor() throws {
        let descriptor = try typeDescriptor(Student.self)
        
        XCTAssertEqual(descriptor.debugDescription, expectedResult().debugDescription)
    }
    
    func expectedResult() -> TypeDescriptor {
        let usersProperty = Property(offset: 1, path: "users", type: .dictionary(key: String.self, value: User.self))
        
        let carProperty = Property(parent: usersProperty, offset: 2, path: "car", type: .optional(Car.self))
        let carProperties: [Property] = [
            .init(parent: carProperty, offset: 0, path: "plateNumber", type: .optional(Int.self)),
            .init(parent: carProperty, offset: 1, path: "color", type: .exactlyOne(String.self))
        ]
        
        carProperty.addProperties(carProperties)
        let usersProperties: [Property] = [
            .init(parent: usersProperty, offset: 0, path: "id", type: .optional(Int.self)),
            .init(parent: usersProperty, offset: 1, path: "_name", type: .exactlyOne(String.self)),
            carProperty
        ]
        
        usersProperty.addProperties(usersProperties)
        
        return TypeDescriptor(
            name: "Student",
            typeWrapper: .exactlyOne(Student.self),
            properties: [
                .init(offset: 0, path: "id", type: .optional(Int.self)),
                usersProperty,
                .init(offset: 2, path: "grades", type: .array(Float.self)),
                .init(offset: 3, path: "name", type: .optional(String.self)),
                .init(offset: 4, path: "surname", type: .exactlyOne(String.self))
            ])
    }
    
    func testCustomEncoding() throws {
        struct SomeCustomEncoding: Encodable {
            private enum CodingKeys: String, CodingKey {
                case hashedIDString = "top_secret"
                case color
                case someRandomOptionalBool
            }
            
            let id: Int
            let cars: [Car]
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                
                try container.encode((0 ... 5).map { "\(id + $0)" }, forKey: .hashedIDString)
                try container.encode(cars.first?.color, forKey: .color)
                try container.encode(Optional<Bool>(.random()), forKey: .someRandomOptionalBool)
            }
        }
        
        let descriptor = try typeDescriptor(SomeCustomEncoding.self)
        
        let expectedResult = TypeDescriptor(
            name: "SomeCustomEncoding",
            typeWrapper: .exactlyOne(SomeCustomEncoding.self),
            properties: [
                .init(offset: 0, path: "top_secret", type: .array(String.self)),
                .init(offset: 1, path: "color", type: .optional(String.self)),
                .init(offset: 2, path: "someRandomOptionalBool", type: .optional(Bool.self)),
            ])
        
        XCTAssertEqual(descriptor.debugDescription, expectedResult.debugDescription)
    }
}

extension Property {
    func addProperties(_ properties: [Property]) {
        self.properties.append(contentsOf: properties)
    }
}
