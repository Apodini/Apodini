//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini

public struct MockStringKey: InformationKey {
    public typealias RawValue = String

    public let key: String

    public init(_ key: String) {
        self.key = key
    }
}

public protocol MockStringInformationClass: InformationClass {
    var entry: (key: String, value: String) { get }
}

public protocol MockString2InformationClass: InformationClass {
    var entry: (key: String, value: String) { get }
}

public protocol MockIntInformationClass: InformationClass {
    var entry: (key: String, value: Int) { get }
}


public struct MockInformation: Information {
    public let key: MockStringKey
    public let value: String

    public init(key: MockStringKey, rawValue: String) {
        self.key = key
        self.value = rawValue
    }
}

extension MockInformation: MockStringInformationClass {}
public extension MockStringInformationClass where Self == MockInformation {
    /// Provides entry
    var entry: (key: String, value: String) {
        (key: self.key.key, value: self.value)
    }
}

extension MockInformation: MockString2InformationClass {}
extension MockString2InformationClass where Self == MockInformation {}

extension MockInformation: MockIntInformationClass {}
public extension MockIntInformationClass where Self == MockInformation {
    /// Provides entry
    var entry: (key: String, value: Int) {
        (key: self.key.key, value: Int(self.value)!)
    }
}

public struct MockIntInformationInstantiatable: InformationInstantiatable {
    public typealias AssociatedInformation = MockInformation

    public static let key = MockStringKey("ExampleStringKey")

    public let rawValue: String
    public let value: Int

    public init?(rawValue: String) {
        guard let number = Int(rawValue) else {
            return nil
        }
        self.rawValue = rawValue
        self.value = number
    }

    public init(_ value: Int) {
        self.rawValue = String(value)
        self.value = value
    }
}
