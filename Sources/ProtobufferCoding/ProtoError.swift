//
//  ProtoError.swift
//  
//
//  Created by Moritz Schüll on 18.11.20.
//

import Foundation

enum ProtoError: Error {
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
