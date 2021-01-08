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
        // Used to parse crontabs in the `Scheduler` class
        .package(url: "https://github.com/MihaelIsaev/SwifCron.git", from:"1.3.0"),
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.11.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.18.0"),
        .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.2.2"),
        // Used for testing purposes only. Enables us to test for assertions, preconditions and fatalErrors.
        .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: "2.0.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "2.1.0")
    ],
    targets: [
        .target(
            name: "Apodini",
            dependencies: [
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
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "SwifCron", package: "SwifCron"),
                .target(name: "WebSocketInfrastructure"),
                .target(name: "ProtobufferCoding")
            ],
            exclude: [
                "Components/ComponentBuilder.swift.gyb"
            ]
        ),
        .target(
            name: "ApodiniDatabase",
            dependencies: [
                .target(name: "Apodini")
            ]
        ),
        .testTarget(
            name: "ApodiniTests",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniDatabase"),
                .product(name: "XCTVapor", package: "vapor"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "CwlPreconditionTesting", package: "CwlPreconditionTesting", condition: .when(platforms: [.macOS]))
            ],
            exclude: [
                "ConfigurationTests/mock_fcm.json",
                "ConfigurationTests/mock_invalid_fcm.json",
                "ConfigurationTests/mock.p8",
                "ConfigurationTests/mock.pem"
            ]
        ),
        .target(
            name: "TestWebService",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniDatabase")
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
        ),
        // WebSocket Infrastructure
        .target(
            name: "WebSocketInfrastructure",
            dependencies: [
                .product(name: "OpenCombine", package: "OpenCombine"),
                .product(name: "OpenCombineFoundation", package: "OpenCombine"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "Runtime", package: "Runtime")
            ]
        )
    ]
)
