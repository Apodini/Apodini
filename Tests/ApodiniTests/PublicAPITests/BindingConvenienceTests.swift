//
//  BindingConvenienceTests.swift
//  
//
//  Created by Max Obermeier on 02.03.21.
//

import Apodini

// This file doesn't test functionality, but only that certain expressions, which
// are considered important use-cases of `Binding`'s public API do compile.

struct AHandler: Handler {
    @Binding var string: String
    @Binding var stringOpt: String?
    @Binding var bool: Bool
    // swiftlint:disable:next discouraged_optional_boolean
    @Binding var boolOpt: Bool?
    @Binding var array: [String]
    // swiftlint:disable:next discouraged_optional_collection
    @Binding var arrayOpt: [Bool]?
    @Binding var set: Set<String>
    // swiftlint:disable:next discouraged_optional_collection
    @Binding var setOpt: Set<Bool>?
    @Binding var float: Float
    @Binding var floatOpt: Float?
    @Binding var double: Double
    @Binding var doubleOpt: Double?
    @Binding var int: Int
    @Binding var intOpt: Int?
    @Binding var uint: UInt
    @Binding var uintOpt: UInt?
    
    
    func handle() throws -> Response<String> {
        .nothing
    }
}

struct Some: Component {
    var content: some Component {
        AHandler(
            string: "string",
            stringOpt: .some("stringOpt"),
            bool: true,
            boolOpt: .some(true),
            array: ["string"],
            arrayOpt: .some([]),
            set: ["string"],
            setOpt: .some([]),
            float: 1.2,
            floatOpt: .some(1.0),
            double: 2.4,
            doubleOpt: .some(2.0),
            int: -5,
            intOpt: .some(-10),
            uint: 5,
            uintOpt: .some(10))
    }
}

struct None: Component {
    var content: some Component {
        AHandler(
            string: "st\("r")ing",
            stringOpt: nil,
            bool: true,
            boolOpt: nil,
            array: ["string"],
            arrayOpt: nil,
            set: ["string"],
            setOpt: nil,
            float: 1.2,
            floatOpt: nil,
            double: 2.4,
            doubleOpt: nil,
            int: -5,
            intOpt: nil,
            uint: 5,
            uintOpt: nil)
    }
}
