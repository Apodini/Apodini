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
    name: "Apodini",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "Apodini", targets: ["Apodini"]),
        .library(name: "ApodiniExtension", targets: ["ApodiniExtension"]),
        .library(name: "ApodiniNetworking", targets: ["ApodiniNetworking"]),
        .library(name: "ApodiniUtils", targets: ["ApodiniUtils"]),
        .library(name: "ApodiniDatabase", targets: ["ApodiniDatabase"]),
        .library(name: "ApodiniGRPC", targets: ["ApodiniGRPC"]),
        .library(name: "ApodiniJobs", targets: ["ApodiniJobs"]),
        .library(name: "ApodiniNotifications", targets: ["ApodiniNotifications"]),
        .library(name: "ApodiniOpenAPI", targets: ["ApodiniOpenAPI"]),
        .library(name: "ApodiniProtobuffer", targets: ["ApodiniProtobuffer"]),
        .library(name: "ApodiniREST", targets: ["ApodiniREST"]),
        .library(name: "ApodiniHTTP", targets: ["ApodiniHTTP"]),
        .library(name: "ApodiniTypeReflection", targets: ["ApodiniTypeReflection"]),
        .library(name: "ApodiniHTTPProtocol", targets: ["ApodiniHTTPProtocol"]),
        .library(name: "ApodiniWebSocket", targets: ["ApodiniWebSocket"]),

        // Authorization
        .library(name: "ApodiniAuthorization", targets: ["ApodiniAuthorization"]),
        .library(name: "ApodiniAuthorizationBasicScheme", targets: ["ApodiniAuthorizationBasicScheme"]),
        .library(name: "ApodiniAuthorizationBearerScheme", targets: ["ApodiniAuthorizationBearerScheme"]),
        .library(name: "ApodiniAuthorizationJWT", targets: ["ApodiniAuthorizationJWT"]),

        // Deploy
        .library(name: "ApodiniDeploy", targets: ["ApodiniDeploy"]),
        .library(name: "ApodiniDeployBuildSupport", targets: ["ApodiniDeployBuildSupport"]),
        .library(name: "ApodiniDeployRuntimeSupport", targets: ["ApodiniDeployRuntimeSupport"]),
        .executable(name: "DeploymentTargetLocalhost", targets: ["DeploymentTargetLocalhost"]),
        .executable(name: "DeploymentTargetAWSLambda", targets: ["DeploymentTargetAWSLambda"]),
        .library(name: "DeploymentTargetLocalhostRuntime", targets: ["DeploymentTargetLocalhostRuntime"]),
        .library(name: "DeploymentTargetAWSLambdaRuntime", targets: ["DeploymentTargetAWSLambdaRuntime"]),
        
        // Observe
        .library(name: "ApodiniObserve", targets: ["ApodiniObserve"]),
        .library(name: "ApodiniLoggingSupport", targets: ["ApodiniLoggingSupport"]),
        
        // Migrator
        .library(name: "ApodiniMigration", targets: ["ApodiniMigration"]),
        
        // Lukas' playground
        .library(name: "ApodiniGRPCv2", targets: ["ApodiniGRPCv2"]),
        .executable(name: "LKTestWebService", targets: ["LKTestWebService"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.13.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.1.0"),
        // Used by the `NotificationCenter` to send push notifications to `APNS`.
        .package(name: "apnswift", url: "https://github.com/kylebrowning/APNSwift.git", from: "3.0.0"),
        // Use to navigate around some of the existentials limitations of the Swift Compiler
        // As AssociatedTypeRequirementsKit does not follow semantic versioning we constraint it to the current minor version
        .package(url: "https://github.com/nerdsupremacist/AssociatedTypeRequirementsKit.git", .upToNextMinor(from: "0.3.2")),
        // Used to parse crontabs in the `Scheduler` class
        .package(url: "https://github.com/MihaelIsaev/SwifCron.git", from: "1.3.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "2.4.0"),
        // Event-driven network application framework for high performance protocol servers & clients, non-blocking.
        // Update to 2.32 or higher once https://github.com/swift-server/swift-aws-lambda-runtime tags a new release with swift-nio 2.32 or higher
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMinor(from: "2.31.0")),
        // Bindings to OpenSSL-compatible libraries for TLS support in SwiftNIO
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.13.0"),
        // HTTP/2 support for SwiftNIO
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.17.0"),
        // Swift logging API
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
        // CLI-Argument parsing in the WebService and ApodiniDeploy
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.4.0")),
        .package(url: "https://github.com/apple/swift-collections", .upToNextMinor(from: "0.0.4")),
        .package(url: "https://github.com/Supereg/Runtime.git", from: "2.2.3"),
        // restore original package url once https://github.com/wickwirew/Runtime/pull/93
        // and https://github.com/wickwirew/Runtime/pull/95 are merged
        // .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.2.3"),
        //.package(url: "https://github.com/PSchmiedmayer/Runtime", .branch("master")),
        
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.0"),
        // Used for testing of the new ExporterConfiguration
        .package(url: "https://github.com/soto-project/soto-core.git", from: "5.3.0"),
        
        // Deploy
        //.package(url: "https://github.com/vapor-community/vapor-aws-lambda-runtime.git", .upToNextMinor(from: "0.6.2")),
        .package(url: "https://github.com/soto-project/soto.git", from: "5.5.0"),
        .package(url: "https://github.com/soto-project/soto-s3-file-transfer", from: "0.3.0"),
        
        // testing runtime crashes
        .package(url: "https://github.com/norio-nomura/XCTAssertCrash.git", from: "0.2.0"),

        // Metadata
        .package(url: "https://github.com/Apodini/MetadataSystem.git", .upToNextMinor(from: "0.1.0")),

        // Apodini Authorization
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        
        // Apodini Migrator
        .package(url: "https://github.com/Apodini/ApodiniMigrator.git", .upToNextMinor(from: "0.1.0")),

        // TypeInformation
        .package(url: "https://github.com/Apodini/ApodiniTypeInformation.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.2.0")
    ],
    targets: [
        .target(name: "CApodiniUtils"),
        .target(
            name: "ApodiniUtils",
            dependencies: [
                .target(name: "CApodiniUtils"),
                .product(name: "Runtime", package: "Runtime"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "NIO", package: "swift-nio")
            ]
        ),
        
        .target(
            name: "Apodini",
            dependencies: [
                .target(name: "ApodiniUtils"),
                .product(name: "ApodiniContext", package: "MetadataSystem"),
                .product(name: "MetadataSystem", package: "MetadataSystem"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Runtime", package: "Runtime"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "TypeInformationMetadata", package: "ApodiniTypeInformation"),
                .product(name: "ApodiniTypeInformation", package: "ApodiniTypeInformation")
            ],
            exclude: [
                "Components/ComponentBuilder.swift.gyb"
            ]
        ),
        
        .target(
            name: "ApodiniExtension",
            dependencies: [
                .target(name: "ApodiniUtils"),
                .target(name: "Apodini"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "_NIOConcurrency", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),

        .testTarget(
            name: "ApodiniTests",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .target(name: "XCTApodini"),
                .target(name: "ApodiniDatabase"),
                .target(name: "ApodiniREST"),
                .target(name: "ApodiniGRPC"),
                .target(name: "ApodiniOpenAPI"),
                .target(name: "ApodiniWebSocket"),
                .target(name: "ApodiniProtobuffer"),
                .target(name: "ApodiniAuthorization"),
                .target(name: "ApodiniMigration"),
                .target(name: "ApodiniAuthorizationBearerScheme"),
                .target(name: "ApodiniAuthorizationBasicScheme"),
                .target(name: "ApodiniAuthorizationJWT"),
                .product(name: "SotoTestUtils", package: "soto-core"),
                .product(name: "OrderedCollections", package: "swift-collections")
            ],
            resources: [
                .process("Resources")
            ]
        ),

        .testTarget(
            name: "NegativeCompileTestsRunner",
            dependencies: [
                .target(name: "ApodiniUtils")
            ]
        ),
        
        .testTarget(
            name: "ApodiniNegativeCompileTests",
            dependencies: [
                .target(name: "Apodini")
            ],
            exclude: ["Cases"]
        ),

        .target(
            name: "ApodiniDatabase",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniNetworking"),
                .product(name: "FluentKit", package: "fluent-kit")
            ]
        ),

        .target(
            name: "ApodiniGRPC",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniExtension"),
                .target(name: "ApodiniNetworking"),
                .target(name: "ApodiniLoggingSupport"),
                .target(name: "ProtobufferCoding")
            ]
        ),

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
        ),

        .target(
            name: "ApodiniNotifications",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniDatabase"),
                .product(name: "APNSwift", package: "apnswift")
            ]
        ),

        .testTarget(
            name: "ApodiniNotificationsTests",
            dependencies: [
                .target(name: "ApodiniNotifications"),
                .target(name: "XCTApodini")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        
        .target(
            name: "ApodiniOpenAPISecurity",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniUtils"),
                .product(name: "OrderedCollections", package: "swift-collections")
            ]
        ),

        .target(
            name: "ApodiniOpenAPI",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniUtils"),
                .target(name: "ApodiniOpenAPISecurity"),
                .target(name: "ApodiniREST"),
                .product(name: "ApodiniTypeInformation", package: "ApodiniTypeInformation"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "Yams", package: "Yams")
            ],
            resources: [
                .process("Resources")
            ]
        ),

        .target(
            name: "ApodiniProtobuffer",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniTypeReflection"),
                .target(name: "ApodiniNetworking"),
                .target(name: "ProtobufferCoding"),
                .target(name: "ApodiniGRPC")
            ]
        ),

        .target(
            name: "ApodiniREST",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniExtension"),
                .target(name: "ApodiniHTTPProtocol"),
                .target(name: "ApodiniNetworking")
            ]
        ),
        
        .target(
            name: "ApodiniHTTP",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniExtension"),
                .target(name: "ApodiniHTTPProtocol"),
                .target(name: "ApodiniNetworking")
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
            name: "ApodiniHTTPProtocol",
            dependencies: [
                .target(name: "Apodini"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ]
        ),
        
        
        .target(
            name: "ApodiniNetworking",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniHTTPProtocol"),
                .target(name: "ApodiniExtension"),
                .target(name: "ApodiniLoggingSupport"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "WebSocketKit", package: "websocket-kit"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        
        .target(
            name: "ApodiniWebSocket",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniUtils"),
                .target(name: "ApodiniExtension"),
                .target(name: "ApodiniNetworking"),
                .target(name: "ApodiniLoggingSupport"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "WebSocketKit", package: "websocket-kit"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "Runtime", package: "Runtime")
            ]
        ),

        // MARK: Apodini Authorization

        .target(
            name: "ApodiniAuthorization",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniOpenAPISecurity")
            ]
        ),

        .target(
            name: "ApodiniAuthorizationBasicScheme",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniHTTPProtocol"),
                .target(name: "ApodiniAuthorization")
            ]
        ),

        .target(
            name: "ApodiniAuthorizationBearerScheme",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniHTTPProtocol"),
                .target(name: "ApodiniAuthorization")
            ]
        ),

        .target(
            name: "ApodiniAuthorizationJWT",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniAuthorization"),
                .target(name: "ApodiniAuthorizationBearerScheme"),
                .product(name: "JWTKit", package: "jwt-kit")
            ]
        ),

        .testTarget(
            name: "ApodiniAuthorizationTests",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniAuthorization"),
                .target(name: "ApodiniAuthorizationBasicScheme"),
                .target(name: "ApodiniAuthorizationBearerScheme"),
                .target(name: "ApodiniAuthorizationJWT"),
                .target(name: "XCTApodini")
            ]
        ),

        // ProtobufferCoding

        .target(
            name: "ProtobufferCoding",
            dependencies: [
                .target(name: "ApodiniUtils"),
                .product(name: "Runtime", package: "Runtime")
            ],
            exclude: ["README.md"]
        ),

        .testTarget(
            name: "ProtobufferCodingTests",
            dependencies: [
                .target(name: "ProtobufferCoding")
            ]
        ),
        
        // ApodiniMigration
        
        .target(
            name: "ApodiniMigration",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniNetworking"),
                .product(name: "ApodiniMigrator", package: "ApodiniMigrator")
            ]
        ),

        // XCTApodini

        .target(
            name: "XCTApodini",
            dependencies: [
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "XCTAssertCrash", package: "XCTAssertCrash", condition: .when(platforms: [.macOS])),
                .target(name: "Apodini"),
                .target(name: "ApodiniExtension"),
                .target(name: "ApodiniDatabase"),
                .target(name: "ApodiniUtils"),
                .target(name: "ApodiniREST"),
                .target(name: "ApodiniNetworking"),
                .target(name: "XCTApodiniNetworking")
            ]
        ),
        
        .target(
            name: "XCTApodiniNetworking",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniNetworking"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        
        
        .executableTarget(
            name: "ApodiniDeployTestWebService",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniDeployBuildSupport"),
                .target(name: "DeploymentTargetLocalhostRuntime"),
                .target(name: "DeploymentTargetAWSLambdaRuntime"),
                .target(name: "ApodiniREST"),
                .target(name: "ApodiniGRPC"),
                .target(name: "ApodiniProtobuffer"),
                .target(name: "ApodiniOpenAPI"),
                .target(name: "ApodiniWebSocket"),
                .target(name: "ApodiniNotifications"),
                .target(name: "ApodiniDeploy")
            ]
        ),
        
        .testTarget(
            name: "ApodiniHTTPTests",
            dependencies: [
                .target(name: "XCTApodini"),
                .target(name: "ApodiniHTTP"),
                .target(name: "ApodiniNetworking"),
                .target(name: "XCTApodiniNetworking")
            ]
        ),
        
        .testTarget(
            name: "ApodiniExtensionTests",
            dependencies: [
                .target(name: "XCTApodini")
            ]
        ),
        
        
        .testTarget(
            name: "ApodiniUtilsTests",
            dependencies: [
                .target(name: "ApodiniUtils")
            ]
        ),
        
        //
        // MARK: Deploy
        //
        
        .target(
            name: "ApodiniDeploy",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniUtils"),
                .target(name: "ApodiniNetworking"),
                .target(name: "ApodiniDeployBuildSupport"),
                .target(name: "ApodiniDeployRuntimeSupport"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        
        .target(
            name: "ApodiniDeployBuildSupport",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniUtils"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Runtime", package: "Runtime")
            ]
        ),
        .target(
            name: "ApodiniDeployRuntimeSupport",
            dependencies: [
                .target(name: "ApodiniDeployBuildSupport"),
                .target(name: "Apodini"),
                .target(name: "ApodiniUtils"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit")
            ]
        ),
        .testTarget(
            name: "ApodiniDeployTests",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "XCTApodini"),
                .target(name: "ApodiniDeployTestWebService"),
                .target(name: "ApodiniUtils"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "SotoLambda", package: "soto"),
                .product(name: "SotoApiGatewayV2", package: "soto"),
                .product(name: "SotoIAM", package: "soto"),
                .target(name: "DeploymentTargetLocalhost"),
                .target(name: "DeploymentTargetAWSLambda")
            ]
        ),
        .executableTarget(
            name: "DeploymentTargetLocalhost",
            dependencies: [
                .target(name: "ApodiniDeployBuildSupport"),
                .target(name: "ApodiniUtils"),
                .target(name: "ApodiniNetworking"),
                .target(name: "DeploymentTargetLocalhostCommon"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .target(
            name: "DeploymentTargetLocalhostCommon",
            dependencies: [
                .target(name: "ApodiniDeployBuildSupport")
            ]
        ),
        .target(
            name: "DeploymentTargetLocalhostRuntime",
            dependencies: [
                .target(name: "DeploymentTargetLocalhostCommon"),
                .target(name: "ApodiniDeployRuntimeSupport"),
                .target(name: "ApodiniOpenAPI")
            ]
        ),

        .executableTarget(
            name: "DeploymentTargetAWSLambda",
            dependencies: [
                .target(name: "DeploymentTargetAWSLambdaCommon"),
                .target(name: "ApodiniDeployBuildSupport"),
                .target(name: "ApodiniUtils"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "SotoLambda", package: "soto"),
                .product(name: "SotoApiGatewayV2", package: "soto"),
                .product(name: "SotoIAM", package: "soto"),
                .product(name: "SotoSTS", package: "soto"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "SotoS3FileTransfer", package: "soto-s3-file-transfer")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "DeploymentTargetAWSLambdaCommon",
            dependencies: [
                .target(name: "ApodiniDeployBuildSupport")
            ]
        ),
        .target(
            name: "DeploymentTargetAWSLambdaRuntime",
            dependencies: [
                .target(name: "DeploymentTargetAWSLambdaCommon"),
                .target(name: "ApodiniDeployRuntimeSupport"),
                .target(name: "ApodiniOpenAPI")
                //.product(name: "VaporAWSLambdaRuntime", package: "vapor-aws-lambda-runtime")
            ]
        ),
        
        //
        // MARK: Observe
        //
        
        .target(
            name: "ApodiniObserve",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniExtension"),
                .target(name: "ApodiniLoggingSupport"),
                .target(name: "ApodiniUtils"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        
        .target(
            name: "ApodiniLoggingSupport",
            dependencies: [
                .target(name: "Apodini"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        
        .target(
            name: "ApodiniGRPCv2",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniExtension"),
                .target(name: "ApodiniNetworking"),
                .target(name: "ApodiniLoggingSupport"),
                .target(name: "ProtobufferCoding"),
                .target(name: "ApodiniTypeReflection"),
                .product(name: "Runtime", package: "Runtime"),
                .product(name: "ApodiniTypeInformation", package: "ApodiniTypeInformation"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit")
            ]
        ),
        
        .executableTarget(
            name: "LKTestWebService",
            dependencies: [
                .target(name: "ApodiniGRPCv2"),
                .target(name: "ApodiniGRPC"),
                .target(name: "ApodiniREST"),
                .target(name: "ApodiniHTTP"),
                .target(name: "Apodini")
            ]
        )
    ]
)
