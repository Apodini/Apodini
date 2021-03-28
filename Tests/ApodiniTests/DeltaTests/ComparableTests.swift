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
    
    struct EndpointName: ComparableProperty {
        let name: String
    }
    
    struct Path: ComparableProperty {
        let path: String
    }
    
    struct SomeParameterName: ComparableProperty {
        let name: String
    }
    
    struct CustomEndpoint: ComparableObject {
        let path: Path
        let name: EndpointName
        let parameters: [SomeParameter]
        
        var deltaIdentifier: DeltaIdentifier { .init("id") }
        
        func compare(to other: CustomEndpoint) -> ChangeContextNode {
            let context = ChangeContextNode()
            
            context.register(compare(\.path, with: other), for: Path.self)
            context.register(compare(\.name, with: other), for: EndpointName.self)
            context.register(compare(\.parameters, with: other), for: [SomeParameter].self)
            
            return context
        }
        
        func evaluate(result: ChangeContextNode) -> Change? {
            let childrenChanges = [
                path.change(in: result)?.change,
                name.change(in: result)?.change,
                parameters.evaluate(node: result)
            ].compactMap { $0 }
            
            guard !childrenChanges.isEmpty else { return nil }
            
            return CompositeChange(location: identifierName, changes: childrenChanges)
        }
    }
    
    struct SomeParameter: ComparableObject {
        
        let id: String
        let name: SomeParameterName
        var deltaIdentifier: DeltaIdentifier { .init(id) }
        
        func compare(to other: SomeParameter) -> ChangeContextNode {
            let context = ChangeContextNode()
            context.register(compare(\.name, with: other), for: SomeParameterName.self)
            return context
        }
        
        func evaluate(result: ChangeContextNode) -> Change? {
            guard let ownContext = change(in: result) else { return nil }
            
            let changes = [
                name.change(in: ownContext)?.change
            ].compactMap { $0 }
            
            guard !changes.isEmpty else { return nil }
            
            return CompositeChange(location: identifierName, changes: changes)
        }
    }

    func testComparision() throws {

        let someParameter1 = SomeParameter(id: "someID", name: .init(name: "user"))
        let someParameter2 = SomeParameter(id: "someOtherID", name: .init(name: "user"))
        
        let customEndpoint = CustomEndpoint(
            path: .init(path: "path1"),
            name: .init(name: "endpoint"),
            parameters: [someParameter1]
        )

        let customEndpoint2 = CustomEndpoint(
            path: .init(path: "path2"),
            name: .init(name: "endpoint"),
            parameters: [someParameter1, someParameter2]
        )

        let context = customEndpoint.compare(to: customEndpoint2)

        let change = try XCTUnwrap(customEndpoint.evaluate(result: context))
        let expectedResult = CompositeChange(
            location: "CustomEndpoint",
            changes: [
                ValueChange(location: "Path", from: Path(path: "path1"), to: .init(path: "path2")),
                CompositeChange(
                    location: "[SomeParameter]",
                    changes: [
                        AddChange(location: "SomeParameter", addedValue: someParameter2)
                    ]
                )
            ]
        )
        
        change.printJSONString()
        
        XCTAssertEqual(change, expectedResult)
    }
}
