// swift-tools-version:5.5

//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "TestWebService",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "TestWebService", targets: ["TestWebService"])
    ],
    dependencies: [
        .package(name: "Apodini", path: "..")
    ],
    targets: [
        .executableTarget(
            name: "TestWebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniGRPC", package: "Apodini"),
                .product(name: "ProtobufferCoding", package: "Apodini"),
                .product(name: "ApodiniOpenAPI", package: "Apodini"),
                .product(name: "ApodiniWebSocket", package: "Apodini"),
                .product(name: "ApodiniMigration", package: "Apodini"),
                .product(name: "ApodiniObserve", package: "Apodini"),
                .product(name: "ApodiniObserveOpenTelemetry", package: "Apodini")
            ]
        )
    ]
)
