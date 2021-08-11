//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTApodini
@testable import ApodiniAuthorization

class AuthorizationRequirementsTests: XCTApodiniTest {
    struct StringAuthenticatable: Authenticatable {
        var someString: String
        var someStringOptional: String?
        var someStringArray: [String]
        var someBool: Bool

        init(_ someString: String = "default", optional: String? = nil, array: String..., bool: Bool = false) {
            self.someString = someString
            self.someStringOptional = optional
            self.someStringArray = array
            self.someBool = bool
        }
    }

    struct IntAuthenticatable: Authenticatable {
        var value: Int
    }

    func testConditionalAuthAllow() throws {
        @AuthorizationRequirementsBuilder<StringAuthenticatable>
        var condition: AuthorizationRequirements<StringAuthenticatable> {
            Allow(ifPresent: \.someStringOptional)
            Allow(if: \.someBool)
            Allow(contains: "Hello", in: \.someStringArray)

            Allow { element in
                element.someString.lowercased() == "test"
            }
        }

        XCTAssertEqual(try condition.evaluate(for: StringAuthenticatable("asdf", array: "None")), .undecided())
        XCTAssertEqual(try condition.evaluate(for: StringAuthenticatable("asdf", array: "Hello")), .fulfilled())
        XCTAssertEqual(try condition.evaluate(for: StringAuthenticatable("asdf", bool: true)), .fulfilled())
        XCTAssertEqual(try condition.evaluate(for: StringAuthenticatable("asdf", optional: "Some Value", bool: false)), .fulfilled())
        XCTAssertEqual(try condition.evaluate(for: StringAuthenticatable("TEST")), .fulfilled())
    }

    func testAlwaysAllow() throws {
        @AuthorizationRequirementsBuilder<StringAuthenticatable>
        var condition: AuthorizationRequirements<StringAuthenticatable> {
            Deny(ifNot: \.someBool)
            Allow()
        }

        XCTAssertEqual(try condition.evaluate(for: StringAuthenticatable("asdf")), .rejected())
        XCTAssertEqual(try condition.evaluate(for: StringAuthenticatable("asdf", bool: true)), .fulfilled())
    }

    func testArrayDeny() throws {
        @AuthorizationRequirementsBuilder<StringAuthenticatable>
        var condition: AuthorizationRequirements<StringAuthenticatable> {
            for index in 0..<5 {
                Deny(notContains: "\(index)", in: \.someStringArray)
            }
        }

        XCTAssertRuntimeFailure(try condition.anyEvaluate(for: IntAuthenticatable(value: 2)))

        XCTAssertEqual(try condition.evaluate(for: StringAuthenticatable(array: "1", "2", "3")), .rejected())
        XCTAssertEqual(try condition.evaluate(for: StringAuthenticatable(array: "1", "2", "3", "0", "4")), .undecided())
    }

    func testEither() throws {
        func build(state: Bool) -> AuthorizationRequirements<StringAuthenticatable> {
            @AuthorizationRequirementsBuilder<StringAuthenticatable>
            var condition: AuthorizationRequirements<StringAuthenticatable> {
                switch state {
                case true:
                    Deny(ifNil: \.someStringOptional)
                case false:
                    Allow(ifNil: \.someStringOptional)
                }

                if state {
                    Allow()
                }
            }

            return condition
        }

        XCTAssertEqual(try build(state: true).evaluate(for: StringAuthenticatable()), .rejected())
        XCTAssertEqual(try build(state: true).evaluate(for: StringAuthenticatable(optional: "SomeValue")), .fulfilled())

        XCTAssertEqual(try build(state: false).evaluate(for: StringAuthenticatable()), .fulfilled())
        XCTAssertEqual(try build(state: false).evaluate(for: StringAuthenticatable(optional: "SomeValue")), .undecided())
    }

    func testAuthConditionOperators() throws {
        @AuthorizationRequirementsBuilder<IntAuthenticatable>
        var condition: AuthorizationRequirements<IntAuthenticatable> {
            Allow(if: (\.value >= 10 || \.value > 15) && (\.value <= 99 || \.value < 75) && true)
            Deny(if: \.value == 50)
            Deny(if: \.value != 52)
            Allow(if: !(\.value != 52))
        }

        XCTAssertEqual(try condition.evaluate(for: IntAuthenticatable(value: 52)), .fulfilled())
    }
}
