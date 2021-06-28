// swift-tools-version:5.4

import PackageDescription


let package = Package(
    name: "Apodini",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Apodini", targets: ["Apodini"]),
        .library(name: "ApodiniUtils", targets: ["ApodiniUtils"]),
        .library(name: "ApodiniDatabase", targets: ["ApodiniDatabase"]),
        .library(name: "ApodiniGRPC", targets: ["ApodiniGRPC"]),
        .library(name: "ApodiniJobs", targets: ["ApodiniJobs"]),
        .library(name: "ApodiniNotifications", targets: ["ApodiniNotifications"]),
        .library(name: "ApodiniOpenAPI", targets: ["ApodiniOpenAPI"]),
        .library(name: "ApodiniProtobuffer", targets: ["ApodiniProtobuffer"]),
        .library(name: "ApodiniREST", targets: ["ApodiniREST"]),
        .library(name: "ApodiniTypeReflection", targets: ["ApodiniTypeReflection"]),
        .library(name: "ApodiniVaporSupport", targets: ["ApodiniVaporSupport"]),
        .library(name: "ApodiniWebSocket", targets: ["ApodiniWebSocket"]),
        // Deploy
        .library(name: "ApodiniDeploy", targets: ["ApodiniDeploy"]),
        .library(name: "ApodiniDeployBuildSupport", targets: ["ApodiniDeployBuildSupport"]),
        .library(name: "ApodiniDeployRuntimeSupport", targets: ["ApodiniDeployRuntimeSupport"]),
        .executable(name: "DeploymentTargetLocalhost", targets: ["DeploymentTargetLocalhost"]),
        .executable(name: "DeploymentTargetAWSLambda", targets: ["DeploymentTargetAWSLambda"]),
        .library(name: "DeploymentTargetLocalhostRuntime", targets: ["DeploymentTargetLocalhostRuntime"]),
        .library(name: "DeploymentTargetAWSLambdaRuntime", targets: ["DeploymentTargetAWSLambdaRuntime"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.45.3"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.2.0"),
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.12.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.1"),
        // Used by the `NotificationCenter` to send push notifications to `APNS`.
        .package(name: "apnswift", url: "https://github.com/kylebrowning/APNSwift.git", from: "3.0.0"),
        // Used by the `NotificationCenter` to send push notifications to `FCM`.
        .package(url: "https://github.com/MihaelIsaev/FCM.git", from: "2.10.1"),
        .package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.2"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.1.2"),
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0"),
        // Use to navigate around some of the existentials limitations of the Swift Compiler
        // As AssociatedTypeRequirementsKit does not follow semantic versioning we constraint it to the current minor version
        .package(url: "https://github.com/nerdsupremacist/AssociatedTypeRequirementsKit.git", .upToNextMinor(from: "0.3.2")),
        // Used to parse crontabs in the `Scheduler` class
        .package(url: "https://github.com/MihaelIsaev/SwifCron.git", from: "1.3.1"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "2.4.0"),
        // OpenCombine seems to be only available as a pre release and is not feature complete.
        // We constrain it to the next minor version as it doen't follow semantic versioning.
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", .upToNextMinor(from: "0.11.0")),
        // Event-driven network application framework for high performance protocol servers & clients, non-blocking.
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.30.0"),
        // Bindings to OpenSSL-compatible libraries for TLS support in SwiftNIO
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.13.1"),
        // HTTP/2 support for SwiftNIO
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.17.0"),
        // Swift logging API
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.2.2"),
        // Used for testing purposes only. Enables us to test for assertions, preconditions and fatalErrors.
        .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: "2.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.6"),
        // Used for testing of the new ExporterConfiguration
        .package(url: "https://github.com/soto-project/soto-core.git", from: "5.0.0"),
        
        // Deploy
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.3"),
        .package(url: "https://github.com/vapor-community/vapor-aws-lambda-runtime", from: "0.6.1"),
        .package(url: "https://github.com/soto-project/soto.git", from: "5.5.0"),
        .package(url: "https://github.com/soto-project/soto-s3-file-transfer", from: "0.3.1")
    ],
    targets: [
        .target(name: "CApodiniUtils"),
        .target(
            name: "ApodiniUtils",
            dependencies: [
                .target(name: "CApodiniUtils"),
                .product(name: "Runtime", package: "Runtime"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        
        .target(
            name: "Apodini",
            dependencies: [
                .target(name: "ApodiniUtils"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Runtime", package: "Runtime"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            exclude: [
                "Components/ComponentBuilder.swift.gyb"
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
                .product(name: "XCTVapor", package: "vapor"),
                .product(name: "OpenCombine", package: "OpenCombine"),
                .product(name: "OpenCombineFoundation", package: "OpenCombine"),
                .product(name: "SotoTestUtils", package: "soto-core")
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
            name: "ApodiniGRPC",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniVaporSupport"),
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
                .target(name: "ApodiniVaporSupport"),
                .target(name: "ApodiniDatabase"),
                .product(name: "APNSwift", package: "apnswift"),
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
            resources: [
                .process("Resources")
            ]
        ),

        .target(
            name: "ApodiniOpenAPI",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniREST"),
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
            name: "ApodiniREST",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniVaporSupport")
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
            name: "ApodiniWebSocket",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniUtils"),
                .target(name: "ApodiniVaporSupport"),
                .product(name: "OpenCombine", package: "OpenCombine"),
                .product(name: "OpenCombineFoundation", package: "OpenCombine"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "Runtime", package: "Runtime")
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

        // XCTApodini

        .target(
            name: "XCTApodini",
            dependencies: [
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "CwlPreconditionTesting", package: "CwlPreconditionTesting", condition: .when(platforms: [.macOS])),
                .target(name: "Apodini"),
                .target(name: "ApodiniDatabase"),
                .target(name: "ApodiniUtils")
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
        
        //
        // MARK: Deploy
        //
        
        .target(
            name: "ApodiniDeploy",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniUtils"),
                .target(name: "ApodiniVaporSupport"),
                .target(name: "ApodiniOpenAPI"),
                .target(name: "ApodiniDeployBuildSupport"),
                .target(name: "ApodiniDeployRuntimeSupport"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit")
            ]
        ),
        
        .target(
            name: "ApodiniDeployBuildSupport",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniUtils"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Runtime", package: "Runtime"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit")
            ]
        ),
        .target(
            name: "ApodiniDeployRuntimeSupport",
            dependencies: [
                .target(name: "ApodiniDeployBuildSupport"),
                .target(name: "Apodini"),
                .target(name: "ApodiniUtils"),
                .target(name: "ApodiniVaporSupport"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit")
            ]
        ),
        .testTarget(
            name: "ApodiniDeployTests",
            dependencies: [
                .target(name: "XCTApodini"),
                .target(name: "ApodiniDeployTestWebService"),
                .target(name: "ApodiniUtils"),
                .product(name: "XCTVapor", package: "vapor"),
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
                .product(name: "Vapor", package: "vapor"),
                .target(name: "ApodiniDeployBuildSupport"),
                .target(name: "ApodiniUtils"),
                .target(name: "DeploymentTargetLocalhostCommon"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log")
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
                .target(name: "ApodiniDeployRuntimeSupport")
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
                .product(name: "VaporAWSLambdaRuntime", package: "vapor-aws-lambda-runtime")
            ]
        )
    ]
)
