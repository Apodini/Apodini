//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation

public enum ProtoError: Error {
    case unknownCodingKey(_ codingKey: CodingKey)
    case unknownType(_ fieldType: Int)
    case decodingError(_ message: String)
    case encodingError(_ message: String)
    case unsupportedDataType(_ message: String)
    case unsupportedDecodingStrategy(_ message: String)
    case unsupportedEncodingStrategy(_ message: String)
    case encodingContainerExist(_ message: String)
    case noEncodingContainer(_ message: String)
}
