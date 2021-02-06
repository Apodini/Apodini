// swift-tools-version:5.3

import PackageDescription


let package = Package(
    name: "Apodini",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Apodini", targets: ["Apodini"]),
        .library(name: "ApodiniVaporSupport", targets: ["ApodiniVaporSupport"]),
        .library(name: "ApodiniREST", targets: ["ApodiniREST"]),
        .library(name: "ApodiniGRPC", targets: ["ApodiniGRPC"]),
        .library(name: "ApodiniOpenAPI", targets: ["ApodiniOpenAPI"]),
        .library(name: "ApodiniWebSocket", targets: ["ApodiniWebSocket"]),
        .library(name: "ApodiniProtobuffer", targets: ["ApodiniProtobuffer"]),
        .library(name: "ApodiniDatabase", targets: ["ApodiniDatabase"]),
        .library(name: "ApodiniNotifications", targets: ["ApodiniNotifications"]),
        .library(name: "ApodiniJobs", targets: ["ApodiniJobs"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.39.1"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.1.0"),
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.1"),
        // Used to parse command line arguments
        .package(url: "https://github.com/vapor/console-kit.git", from: "4.2.4"),
        // Used by the `NotificationCenter` to send push notifications to `APNS`.
        .package(url: "https://github.com/vapor/apns.git", from: "1.0.1"),
        // Used by the `NotificationCenter` to send push notifications to `FCM`.
        .package(url: "https://github.com/MihaelIsaev/FCM.git", from: "2.8.0"),
        .package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.2"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.1.2"),
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0"),
        // Use to navigate around some of the existentials limitations of the Swift Compiler
        // As AssociatedTypeRequirementsKit does not follow semantic versioning we constraint it to the current minor version
        .package(url: "https://github.com/nerdsupremacist/AssociatedTypeRequirementsKit.git", .upToNextMinor(from: "0.3.2")),
        // Used to parse crontabs in the `Scheduler` class
        .package(url: "https://github.com/MihaelIsaev/SwifCron.git", from:"1.3.0"),
        // OpenCombine seems to be only available as a pre release and is not feature complete.
        // We constrain it to the next minor version as it doen't follow semantic versioning.
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", .upToNextMinor(from: "0.11.0")),
        // Event-driven network application framework for high performance protocol servers & clients, non-blocking.
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.18.0"),
        // Bindings to OpenSSL-compatible libraries for TLS support in SwiftNIO
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.8.0"),
        // HTTP/2 support for SwiftNIO
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.13.0"),
        // Swift logging API
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.2.2"),
        // Used for testing purposes only. Enables us to test for assertions, preconditions and fatalErrors.
        .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: "2.0.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "2.4.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "Apodini",
            dependencies: [
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Runtime", package: "Runtime"),
                .product(name: "ConsoleKit", package: "console-kit")
            ],
            exclude: [
                "Components/ComponentBuilder.swift.gyb",
                "Relationships/RelationshipIdentificationBuilder.swift.gyb"
            ]
        ),
        .target(
            name: "ApodiniDatabase",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniVaporSupport"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentKit", package: "fluent-kit"),
                .product(name: "FluentMongoDriver", package: "fluent-mongo-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
            ]
        ),

        .target(
            name: "ApodiniTypeReflection",
            dependencies: [
                .target(name: "Apodini"),
                .product(name: "Runtime", package: "Runtime")
            ]
        ),

        .target(
            name: "ApodiniVaporSupport",
            dependencies: [
                .target(name: "Apodini"),
                .product(name: "Vapor", package: "vapor")
            ]
        ),

        .target(
            name: "ApodiniREST",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniVaporSupport"),
                .product(name: "FluentKit", package: "fluent-kit")
            ]
        ),

        .target(
            name: "ApodiniREST",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniVaporSupport"),
                .product(name: "FluentKit", package: "fluent-kit")
            ]
        ),

        .target(
            name: "ApodiniGRPC",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniVaporSupport"),
                .target(name: "ProtobufferCoding")
            ]
        ),

        .target(
            name: "ApodiniOpenAPI",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniVaporSupport"),
                .target(name: "ApodiniTypeReflection"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "Yams", package: "Yams")
            ],
            resources: [
                .process("Resources")
            ]
        ),

        .target(
            name: "ApodiniWebSocket",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniVaporSupport"),
                .product(name: "OpenCombine", package: "OpenCombine"),
                .product(name: "OpenCombineFoundation", package: "OpenCombine"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "Runtime", package: "Runtime")
            ]
        ),

        .target(
            name: "ApodiniProtobuffer",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniTypeReflection"),
                .target(name: "ApodiniVaporSupport"),
                .target(name: "ProtobufferCoding"),
                .target(name: "ApodiniGRPC")
            ]
        ),

        .target(
            name: "ApodiniNotifications",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniVaporSupport"),
                .target(name: "ApodiniDatabase"),
                .product(name: "APNS", package: "apns"),
                .product(name: "FCM", package: "FCM")
            ]
        ),

        .testTarget(
            name: "ApodiniNotificationsTests",
            dependencies: [
                .product(name: "XCTVapor", package: "vapor"),
                .target(name: "ApodiniNotifications"),
                .target(name: "XCTApodini")
            ],
            exclude: [
                "Helper/mock_fcm.json",
                "Helper/mock_invalid_fcm.json",
                "Helper/mock.p8",
                "Helper/mock.pem"
            ]
        ),

        .target(
            name: "XCTApodini",
            dependencies: [
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "CwlPreconditionTesting", package: "CwlPreconditionTesting", condition: .when(platforms: [.macOS])),
                .target(name: "Apodini"),
                .target(name: "ApodiniVaporSupport"),
                .target(name: "ApodiniREST"),
                .target(name: "ApodiniGRPC"),
                .target(name: "ApodiniProtobuffer"),
                .target(name: "ApodiniOpenAPI"),
                .target(name: "ApodiniWebSocket"),
                .target(name: "ApodiniNotifications")
            ]
        ),
        .testTarget(
            name: "ApodiniTests",
            dependencies: [
                .target(name: "XCTApodini"),
                .target(name: "ApodiniDatabase"),
                .product(name: "XCTVapor", package: "vapor"),
                .product(name: "OpenCombine", package: "OpenCombine"),
                .product(name: "OpenCombineFoundation", package: "OpenCombine")
            ],
            exclude: [
                "ConfigurationTests/Certificates/cert.pem",
                "ConfigurationTests/Certificates/key.pem",
                "ConfigurationTests/Certificates/key2.pem"
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

        // ApodiniJobs
        .target(
            name: "ApodiniJobs",
            dependencies: [
                .target(name: "Apodini"),
                .product(name: "SwifCron", package: "SwifCron")
            ]
        ),
        .testTarget(
            name: "ApodiniJobsTests",
            dependencies: [
                .target(name: "ApodiniJobs"),
                .target(name: "XCTApodini")
            ]
        )
    ]
)
