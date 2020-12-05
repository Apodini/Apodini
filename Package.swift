// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Apodini",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Apodini", targets: ["Apodini"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.35.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.1"),
        .package(url: "https://github.com/nerdsupremacist/AssociatedTypeRequirementsKit.git", from: "0.2.0"),
        .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.2.2")
    ],
    targets: [
        .target(
            name: "Apodini",
            dependencies: [
                .target(name: "ProtobufferBuilder"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "Runtime", package: "Runtime"),
            ],
            exclude: [
                "Components/ComponentBuilder.swift.gyb"
            ]
        ),
        .testTarget(
            name: "ApodiniTests",
            dependencies: [
                .product(name: "XCTVapor", package: "vapor"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
            ]
        ),
        .target(
            name: "TestWebService",
            dependencies: [
                .target(name: "Apodini")
            ]
        ),
        // ProtoBufferBuilder
        .target(
            name: "ProtobufferBuilder",
            dependencies: ["Runtime"]
        ),
        .testTarget(
            name: "ProtobufferBuilderTests",
            dependencies: [
                .target(name: "ProtobufferBuilder"),
                .target(name: "Apodini"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
    ]
)
