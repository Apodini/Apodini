//
//  MockModel.swift
//  
//
//  Created by Paul Schmiedmayer on 2/20/21.
//

@testable import ApodiniDatabase
import Foundation


final class MockModel: Model {
    struct CustomStruct: Codable {
        let name: String
    }
    
    struct CustomLosslessStringConvertibleStruct: Codable, LosslessStringConvertible {
        var description: String {
            name
        }
        
        init?(_ description: String) {
            self.name = description
        }
        
        let name: String
    }
    
    enum CustomEnum: String, Codable {
        case test
        case anOtherTest
    }
    
    enum CustomLosslessStringConvertibleEnum: String, Codable, LosslessStringConvertible {
        case test
        case anOtherTest
        
        var description: String {
            self.rawValue
        }
        
        init?(_ rawValue: String) {
            switch rawValue {
            case Self.test.rawValue:
                self = .test
            case Self.anOtherTest.rawValue:
                self = .anOtherTest
            default:
                return nil
            }
        }
    }
    
    
    static var schema: String = "MockModel"
    
    
    @ID
    var id: UUID?
    
    @Field(key: "uint8Column")
    var uint8: UInt8
    
    @Field(key: "stringColumn")
    var string: String
    
    @Field(key: "int64Column")
    var int64: Int64
    
    @Field(key: "boolColumn")
    var bool: Bool
    
    @Field(key: "floatColumn")
    var float: Float
    
    @Field(key: "customStructColumn")
    var customStruct: CustomStruct
    
    @Field(key: "customLosslessStringConvertibleStructColumn")
    var customLosslessStringConvertibleStruct: CustomLosslessStringConvertibleStruct
    
    @Enum(key: "customEnumColumn")
    var customEnum: CustomEnum
    
    @Enum(key: "customLosslessStringConvertibleEnumColumn")
    var customLosslessStringConvertibleEnum: CustomLosslessStringConvertibleEnum
    
    
    init() {}
}
