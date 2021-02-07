//
//  Created by Lorena Schlesinger on 1/15/21.
//

import XCTest
import ApodiniTypeReflection
@_implementationOnly import Runtime

@testable import Apodini

class ReflectionInfoTests: ApodiniTests {
    func testCardinalityIsEquatable() throws {
        let keyType = ReflectionInfo(
            typeInfo: try typeInfo(of: String.self),
            propertyInfo: nil
        )
        let valueType = ReflectionInfo(
            typeInfo: try typeInfo(of: Int.self),
            propertyInfo: nil
        )
        
        XCTAssertEqual(
            ReflectionInfo.Cardinality.zeroToOne,
            ReflectionInfo.Cardinality.zeroToOne
        )
        XCTAssertEqual(
            ReflectionInfo.Cardinality.exactlyOne,
            ReflectionInfo.Cardinality.exactlyOne
        )
        XCTAssertEqual(
            ReflectionInfo.Cardinality.zeroToMany(.array),
            ReflectionInfo.Cardinality.zeroToMany(.array)
        )
        XCTAssertEqual(
            ReflectionInfo.Cardinality.zeroToMany(
                .dictionary(
                    key: keyType,
                    value: valueType
                )
            ),
            ReflectionInfo.Cardinality.zeroToMany(
                .dictionary(
                    key: keyType,
                    value: valueType
                )
            )
        )
        XCTAssertNotEqual(
            ReflectionInfo.Cardinality.zeroToMany(
                .array
            ),
            ReflectionInfo.Cardinality.zeroToMany(
                .dictionary(
                    key: keyType,
                    value: valueType
                )
            )
        )
        XCTAssertNotEqual(
            ReflectionInfo.Cardinality.zeroToOne,
            ReflectionInfo.Cardinality.exactlyOne
        )
        XCTAssertNotEqual(
            ReflectionInfo.Cardinality.zeroToOne,
            ReflectionInfo.Cardinality.zeroToMany(.array)
        )
        XCTAssertNotEqual(
            ReflectionInfo.Cardinality.exactlyOne,
            ReflectionInfo.Cardinality.zeroToMany(.array)
        )
    }

    func testCollectionContextIsEquatable() throws {
        let keyType = ReflectionInfo(
            typeInfo: try typeInfo(of: String.self),
            propertyInfo: nil
        )
        let valueType = ReflectionInfo(
            typeInfo: try typeInfo(of: Int.self),
            propertyInfo: nil
        )
        let valueType1 = ReflectionInfo(
            typeInfo: try typeInfo(of: String.self),
            propertyInfo: nil
        )
        
        XCTAssertEqual(
            ReflectionInfo.CollectionContext.array,
            ReflectionInfo.CollectionContext.array
        )
        XCTAssertEqual(
            ReflectionInfo.CollectionContext.dictionary(key: keyType, value: valueType),
            ReflectionInfo.CollectionContext.dictionary(key: keyType, value: valueType)
        )
        XCTAssertNotEqual(
            ReflectionInfo.CollectionContext.dictionary(key: keyType, value: valueType),
            ReflectionInfo.CollectionContext.array
        )
        XCTAssertNotEqual(
            ReflectionInfo.CollectionContext.dictionary(key: keyType, value: valueType),
            ReflectionInfo.CollectionContext.dictionary(key: keyType, value: valueType1)
        )
    }

    func testReflectionInfoIsEquatable() throws {
        let stringType = ReflectionInfo(
            typeInfo: try typeInfo(of: String.self),
            propertyInfo: nil
        )
        let stringType1 = ReflectionInfo(
            typeInfo: try typeInfo(of: String.self),
            propertyInfo: nil
        )
        let intType = ReflectionInfo(
            typeInfo: try typeInfo(of: Int.self),
            propertyInfo: nil
        )
        let complexReflectedType = try typeInfo(of: Array<Int>.self)
        let complexReflectedTypeProperty = try typeInfo(of: complexReflectedType.properties[0].type)
        let complexTypePropertyInfo = ReflectionInfo(
            typeInfo: complexReflectedTypeProperty,
            propertyInfo: .init(
                name: complexReflectedType.properties[0].name,
                offset: 0
            ),
            cardinality: .exactlyOne
        )
        let complexTypePropertyInfo1 = ReflectionInfo(
            typeInfo: complexReflectedTypeProperty,
            propertyInfo: .init(
                name: "",
                offset: 0
            ),
            cardinality: .exactlyOne
        )
        let complexTypePropertyInfo2 = ReflectionInfo(
            typeInfo: complexReflectedTypeProperty,
            propertyInfo: .init(
                name: complexReflectedType.properties[0].name,
                offset: 1
            ),
            cardinality: .exactlyOne
        )
        let complexTypePropertyInfo3 = ReflectionInfo(
            typeInfo: complexReflectedTypeProperty,
            propertyInfo: .init(
                name: complexReflectedType.properties[0].name,
                offset: 0
            ),
            cardinality: .zeroToOne
        )
        
        XCTAssertEqual(stringType, stringType1)
        XCTAssertNotEqual(stringType, intType)
        XCTAssertNotEqual(complexTypePropertyInfo, stringType)
        XCTAssertEqual(complexTypePropertyInfo, complexTypePropertyInfo)
        XCTAssertNotEqual(complexTypePropertyInfo, complexTypePropertyInfo1)
        XCTAssertNotEqual(complexTypePropertyInfo, complexTypePropertyInfo2)
        XCTAssertNotEqual(complexTypePropertyInfo, complexTypePropertyInfo3)
    }
}
