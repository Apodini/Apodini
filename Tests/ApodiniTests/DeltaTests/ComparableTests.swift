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
    class EndpointName: PropertyValueWrapper<String> {}
    class Path: PropertyValueWrapper<String> {}
    class SomeParameterName: PropertyValueWrapper<String> {}

    struct CustomEndpoint: ComparableObject {
        let path: Path
        let name: EndpointName
        let parameters: [SomeParameter]

        var deltaIdentifier: DeltaIdentifier { .init("id") }

        func compare(to other: CustomEndpoint) -> ChangeContextNode {
            ChangeContextNode()
                .register(compare(\.path, with: other), for: Path.self)
                .register(compare(\.name, with: other), for: EndpointName.self)
                .register(result: compare(\.parameters, with: other), for: SomeParameter.self)
        }

        func evaluate(result: ChangeContextNode, embeddedInCollection: Bool) -> Change? {
            let childrenChanges = [
                path.change(in: result),
                name.change(in: result),
                parameters.evaluate(node: result)
            ].compactMap { $0 }

            guard !childrenChanges.isEmpty else {
                return nil
            }

            return .compositeChange(location: Self.changeLocation, changes: childrenChanges)
        }
    }

    struct SomeParameter: ComparableObject {
        let id: String
        let name: SomeParameterName
        var deltaIdentifier: DeltaIdentifier { .init(id) }

        func compare(to other: SomeParameter) -> ChangeContextNode {
            ChangeContextNode()
                .register(compare(\.name, with: other), for: SomeParameterName.self)
        }

        func evaluate(result: ChangeContextNode, embeddedInCollection: Bool) -> Change? {
            guard let context = context(from: result, embeddedInCollection: embeddedInCollection) else {
                return nil
            }

            let changes = [
                name.change(in: context)
            ].compactMap { $0 }

            guard !changes.isEmpty else {
                return nil
            }

            return .compositeChange(location: Self.changeLocation, changes: changes)
        }
}

    func testComparision() throws {
        let sameIDParameter1 = SomeParameter(id: "someID", name: .init("user"))
        let sameIDParameter2 = SomeParameter(id: "someID", name: .init("user2"))
        let someParameter3 = SomeParameter(id: "someOtherID", name: .init("user"))

        let customEndpoint = CustomEndpoint(
            path: .init("path1"),
            name: .init("endpoint"),
            parameters: [sameIDParameter1]
        )

        let customEndpoint2 = CustomEndpoint(
            path: .init("path2"),
            name: .init("endpoint"),
            parameters: [sameIDParameter2, someParameter3]
        )

        let context = customEndpoint.compare(to: customEndpoint2)

        let change = try XCTUnwrap(customEndpoint.evaluate(result: context, embeddedInCollection: false))
        let expectedResult: Change = .compositeChange(
            location: "CustomEndpoint",
            changes: [
                .valueChange(location: "Path", from: Path("path1"), to: .init("path2")),
                .compositeChange(
                    location: "[SomeParameter]",
                    changes: [
                        .compositeChange(location: "SomeParameter", changes: [
                            .valueChange(location: "SomeParameterName", from: SomeParameterName("user"), to: .init("user2"))
                        ]),
                        .addChange(location: "SomeParameter", addedValue: someParameter3)
                    ]
                )
            ]
        )

        change.printJSONString()

        XCTAssertEqual(change, expectedResult)
    }
}
