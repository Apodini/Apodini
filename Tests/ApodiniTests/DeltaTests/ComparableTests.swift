//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation
import XCTest
@testable import ApodiniDelta

final class ComparableTests: XCTestCase {
    
    struct EndpointName: ComparableProperty, CustomStringConvertible {
        let name: String
        
        var description: String {
            name
        }
    }
    
    struct Path: ComparableProperty, CustomStringConvertible {
        let path: String
        
        var description: String {
            path
        }
    }
    
    struct CustomEndpoint: ComparableObject {
        let path: Path
        let name: EndpointName
        let moreComplexProperty: MoreComplexProperty
        
        func compare(to other: CustomEndpoint) -> ChangeContextNode {
            let context = ChangeContextNode()
            
            context.register(compare(\.path, with: other), for: Path.self)
            context.register(compare(\.name, with: other), for: EndpointName.self)
            context.register(compare(\.moreComplexProperty, with: other), for: MoreComplexProperty.self)
            
            return context
        }
        
        func evaluate(result: ChangeContextNode) -> Change? {
            let childrenChanges = [
                path.change(in: result)?.valueChange,
                name.change(in: result)?.valueChange,
                moreComplexProperty.evaluate(result: result)
            ].compactMap { $0 }
            
            guard !childrenChanges.isEmpty else { return nil }
            
            return CompositeChange(location: identifierName, changes: childrenChanges)
        }
    }
    
    struct MoreComplexProperty: ComparableObject {
        
        func compare(to other: MoreComplexProperty) -> ChangeContextNode {
            let context = ChangeContextNode()
            context.register(compare(\.name, with: other), for: MoreComplexPropertyName.self)
            return context
        }
        
        func evaluate(result: ChangeContextNode) -> Change? {
            guard let ownContext = change(in: result) else { return nil }
            
            let changes = [
                name.change(in: ownContext)?.valueChange
            ].compactMap { $0 }
            
            guard !changes.isEmpty else { return nil }
            
            return CompositeChange(location: identifierName, changes: changes)
        }
        
        struct MoreComplexPropertyName: ComparableProperty, CustomStringConvertible {
            let name: String
            
            var description: String {
                name
            }
        }
        
        let name: MoreComplexPropertyName
    }

    func testComparision() throws {
        
        let customEndpoint = CustomEndpoint(
            path: .init(path: "path1"),
            name: .init(name: "endpoint"),
            moreComplexProperty: .init(name: .init(name: "user"))
        )
        
        let customEndpoint2 = CustomEndpoint(
            path: .init(path: "path2"),
            name: .init(name: "endpoint"),
            moreComplexProperty: .init(name: .init(name: "user2"))
        )
        
        let context = customEndpoint.compare(to: customEndpoint2)
        
        let change = try XCTUnwrap(customEndpoint.evaluate(result: context))
        let expectedResult = CompositeChange(
            location: "CustomEndpoint",
            changes: [
                ValueChange(location: "Path", from: "path1", to: "path2"),
                CompositeChange(
                    location: "MoreComplexProperty",
                    changes: [
                        ValueChange(location: "MoreComplexPropertyName", from: "user", to: "user2")
                    ]
                )
            ]
        )
        
        XCTAssertEqual(change, expectedResult)
        
    }
}
