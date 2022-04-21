//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation
@testable import ProtobufferCoding
import XCTest


private struct Person: Codable {
    enum EmploymentStatus: Int32, ProtobufEnum {
        case employed, student, unemployed
    }
    let name: String
    let age: Int
    let employmentStatus: EmploymentStatus?
}

private enum Genre: Int32, ProtobufEnum {
    case deathcore
    case doomMetal
    case blackMetal
}

private struct Album: Codable {
    let name: String
    let artist: String
    let genre: Genre
}


class ProtobufferCodingSchemaTests: XCTestCase {
    func testSchemaExport() throws {
        let schema = ProtoSchema(defaultPackageName: "de.lukaskollmer")
        let genreProtoType = try schema.informAboutType(Genre.self)
        XCTAssertEqual(genreProtoType, .enumTy(
            name: .init(packageName: "de.lukaskollmer", typename: "Genre"),
            enumType: Genre.self,
            cases: [
                .init(name: "deathcore", value: 0),
                .init(name: "doomMetal", value: 1),
                .init(name: "blackMetal", value: 2)
            ]
        ))
        let albumProtoType = try schema.informAboutType(Album.self)
        XCTAssertEqual(albumProtoType, .message(
            name: .init(packageName: "de.lukaskollmer", typename: "Album"),
            underlyingType: Album.self,
            nestedOneofTypes: [],
            fields: [
                .init(
                    name: "name",
                    fieldNumber: 1,
                    type: .primitive(String.self),
                    isOptional: false,
                    isRepeated: false,
                    isPacked: false,
                    containingOneof: nil
                ),
                .init(
                    name: "artist",
                    fieldNumber: 2,
                    type: .primitive(String.self),
                    isOptional: false,
                    isRepeated: false,
                    isPacked: false,
                    containingOneof: nil
                ),
                .init(
                    name: "genre",
                    fieldNumber: 3,
                    type: genreProtoType,
                    isOptional: false,
                    isRepeated: false,
                    isPacked: false,
                    containingOneof: nil
                )
            ]
        ))
        let personProtoType = try schema.informAboutType(Person.self)
        let employmentStatusProtoType = try XCTUnwrap(schema.allEnumTypes[.init(packageName: "de.lukaskollmer", typename: "Person.EmploymentStatus")])
        XCTAssertEqual(employmentStatusProtoType, .enumTy(
            name: .init(packageName: "de.lukaskollmer", typename: "Person.EmploymentStatus"),
            enumType: Person.EmploymentStatus.self,
            cases: [
                .init(name: "employed", value: 0),
                .init(name: "student", value: 1),
                .init(name: "unemployed", value: 2)
            ]
        ))
        XCTAssertEqual(personProtoType, .message(
            name: .init(packageName: "de.lukaskollmer", typename: "Person"),
            underlyingType: Person.self,
            nestedOneofTypes: [],
            fields: [
                .init(
                    name: "name",
                    fieldNumber: 1,
                    type: .primitive(String.self),
                    isOptional: false,
                    isRepeated: false,
                    isPacked: false,
                    containingOneof: nil
                ),
                .init(
                    name: "age",
                    fieldNumber: 2,
                    type: .primitive(Int.self),
                    isOptional: false,
                    isRepeated: false,
                    isPacked: false,
                    containingOneof: nil
                ),
                .init(
                    name: "employmentStatus",
                    fieldNumber: 3,
                    type: employmentStatusProtoType,
                    isOptional: true,
                    isRepeated: false,
                    isPacked: false,
                    containingOneof: nil
                )
            ]
        ))
        
        try schema.finalize()
        XCTAssertEqual(schema.finalizedPackages.count, 1)
        let finalisedPackage = schema.finalizedPackages.first!.value
        let packageDescriptor = FileDescriptorProto(
            name: "de/lukaskollmer.proto", // TODO
            package: "de.lukaskollmer",
            dependencies: [],
            publicDependency: [],
            weakDependency: [],
            messageTypes: finalisedPackage.messageTypes,
            enumTypes: finalisedPackage.enumTypes,
            services: [],
            extensions: [],
            options: nil,
            sourceCodeInfo: nil,
            syntax: ProtoSyntax.proto3.rawValue
        )
        let packageDescString = ProtoPrinter.print(packageDescriptor)
        XCTAssert(packageDescString.hasPrefix("""
        // de/lukaskollmer.proto
        //
        // Auto-generated by ApodiniGRPC, at
        """))
        //XCTAssertEqual(packageDescString.split(separator: "\n").dropFirst(3).joined(separator: "\n"), """
        XCTAssertEqual(packageDescString.components(separatedBy: "\n").dropFirst(3).joined(separator: "\n").trimmingLeadingAndTrailingWhitespace(), """
        syntax = "proto3";
        
        package de.lukaskollmer;
        
        
        message Album {
          string name = 1;
          string artist = 2;
          .de.lukaskollmer.Genre genre = 3;
        }
        
        
        message Person {
          string name = 1;
          int64 age = 2;
          optional .de.lukaskollmer.Person.EmploymentStatus employmentStatus = 3;
          enum EmploymentStatus {
            employed = 0;
            student = 1;
            unemployed = 2;
          }
        }
        
        
        enum Genre {
          deathcore = 0;
          doomMetal = 1;
          blackMetal = 2;
        }
        """)
    }
}
