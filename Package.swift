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
        // Used by the `NotificationCenter` to send push notifications to `APNS`.
        .package(url: "https://github.com/vapor/apns.git", from: "1.0.0"),
        // Used by the `NotificationCenter` to send push notifications to `FCM`.
        .package(url: "https://github.com/MihaelIsaev/FCM.git", from: "2.8.0"),
        .package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/nerdsupremacist/AssociatedTypeRequirementsKit.git", from: "0.2.0"),
        // Used by target ProtobufferBuilder to inspect `Type`s.
        .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.2.2")
    ],
    targets: [
        .target(
            name: "Apodini",
            dependencies: [
                .target(name: "ProtobufferBuilder"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "APNS", package: "apns"),
                .product(name: "FCM", package: "FCM"),
                .product(name: "FluentMongoDriver", package: "fluent-mongo-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "Runtime", package: "Runtime"),
                .target(name: "ProtobufferCoding")
            ],
            exclude: [
                "Components/ComponentBuilder.swift.gyb"
            ]
        ),
        .testTarget(
            name: "ApodiniTests",
            dependencies: [
                .target(name: "Apodini"),
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
            dependencies: [
                .product(name: "Runtime", package: "Runtime")
            ]
        ),
        .testTarget(
            name: "ProtobufferBuilderTests",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ProtobufferBuilder"),
                .product(name: "XCTVapor", package: "vapor")
            ]
        ),
        // ProtobufferCoding
        .target(
            name: "ProtobufferCoding",
            dependencies: [
                .product(name: "Runtime", package: "Runtime")
            ],
            exclude:["README.md"]
        ),
        .testTarget(
            name: "ProtobufferCodingTests",
            dependencies: [
                .target(name: "ProtobufferCoding")
            ]
        )
    ]
)
