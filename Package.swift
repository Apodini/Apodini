// swift-tools-version:5.3

import PackageDescription


let package = Package(
    name: "Apodini",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(name: "Apodini", targets: ["Apodini"]),
        .library(name: "ApodiniDatabase", targets: ["ApodiniDatabase"]),
        .library(name: "Notifications", targets: ["Notifications"]),
        .library(name: "Jobs", targets: ["Jobs"]),
        // Deploy
        .library(name: "ApodiniDeployBuildSupport", targets: ["ApodiniDeployBuildSupport"]),
        .library(name: "ApodiniDeployRuntimeSupport", targets: ["ApodiniDeployRuntimeSupport"]),
        .executable(name: "DeploymentTargetLocalhost", targets: ["DeploymentTargetLocalhost"]),
        .executable(name: "DeploymentTargetAWSLambda", targets: ["DeploymentTargetAWSLambda"]),
        .library(name: "DeploymentTargetLocalhostRuntimeSupport", targets: ["DeploymentTargetLocalhostRuntimeSupport"]),
        .library(name: "DeploymentTargetAWSLambdaRuntime", targets: ["DeploymentTargetAWSLambdaRuntime"])
    ],
    dependencies: [
        //.package(name: "ApodiniDeploy", path: "./ApodiniDeploy"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.39.1"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.1.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.1"),
        // Used by the `NotificationCenter` to send push notifications to `APNS`.
        .package(url: "https://github.com/vapor/apns.git", from: "1.0.1"),
        // Used by the `NotificationCenter` to send push notifications to `FCM`.
        .package(url: "https://github.com/MihaelIsaev/FCM.git", from: "2.8.0"),
        .package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.2"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.1.2"),
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0"),
        // Use to navigate around some of the existentials limitations of the Swift Compiler
        // As AssociatedTypeRequirementsKit does not follow semantic versioning we constraint it to the current minor version
        .package(url: "https://github.com/nerdsupremacist/AssociatedTypeRequirementsKit.git", .upToNextMinor(from: "0.3.0")),
        // Used to parse crontabs in the `Scheduler` class
        .package(url: "https://github.com/MihaelIsaev/SwifCron.git", from:"1.3.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "2.4.0"),
        // OpenCombine seems to be only available as a pre release and is not feature complete.
        // We constrain it to the next minor version as it doen't follow semantic versioning.
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", .upToNextMinor(from: "0.11.0")),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.25.1"),
        .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.2.2"),
        // Used for testing purposes only. Enables us to test for assertions, preconditions and fatalErrors.
        .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: "2.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.0"),
        // Used to parse command line arguments
        .package(url: "https://github.com/vapor/console-kit.git", from: "4.2.4"),

        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "0.1.0"),
        .package(url: "https://github.com/vapor-community/vapor-aws-lambda-runtime", .upToNextMajor(from: "0.4.0")),
        .package(url: "https://github.com/soto-project/soto.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "Apodini",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit"),
                .product(name: "Runtime", package: "Runtime"),
                .product(name: "APNS", package: "apns"),
                .product(name: "FCM", package: "FCM"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "ConsoleKit", package: "console-kit"),
                .product(name: "Yams", package: "Yams"),
                .target(name: "WebSocketInfrastructure"),
                .target(name: "ProtobufferCoding"),
                .target(name: "ApodiniDeployBuildSupport"),
                .target(name: "ApodiniDeployRuntimeSupport")
            ],
            exclude: [
                "Components/ComponentBuilder.swift.gyb",
                "Relationships/RelationshipIdentificationBuilder.swift.gyb"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "ApodiniDatabase",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMongoDriver", package: "fluent-mongo-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                .target(name: "Apodini")
            ]
        ),
        .target(
            name: "XCTApodini",
            dependencies: [
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "CwlPreconditionTesting", package: "CwlPreconditionTesting", condition: .when(platforms: [.macOS])),
                .target(name: "Apodini")
            ]
        ),
        .testTarget(
            name: "ApodiniTests",
            dependencies: [
                .product(name: "XCTVapor", package: "vapor"),
                .target(name: "XCTApodini"),
                .target(name: "ApodiniDatabase")
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
        ),
        // Jobs
        .target(
            name: "Jobs",
            dependencies: [
                .target(name: "Apodini"),
                .product(name: "SwifCron", package: "SwifCron")
            ]
        ),
        .testTarget(
            name: "JobsTests",
            dependencies: [
                .target(name: "Jobs"),
                .target(name: "XCTApodini")
            ]
        ),
        // Notifications
        .target(
            name: "Notifications",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniDatabase")
            ]
        ),
        .testTarget(
            name: "NotificationsTests",
            dependencies: [
                .product(name: "XCTVapor", package: "vapor"),
                .target(name: "Notifications"),
                .target(name: "XCTApodini")
            ],
            exclude: [
                "Helper/mock_fcm.json",
                "Helper/mock_invalid_fcm.json",
                "Helper/mock.p8",
                "Helper/mock.pem"
            ]
        ),

        //
        // MARK: Deploy
        //
        .target(name: "CApodiniDeployBuildSupport"),
        .target(
            name: "ApodiniDeployBuildSupport",
            dependencies: [
                .target(name: "CApodiniDeployBuildSupport"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Runtime", package: "Runtime")
            ]
        ),
        .target(
            name: "ApodiniDeployRuntimeSupport",
            dependencies: [
                .target(name: "ApodiniDeployBuildSupport"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit")
            ]
        ),
        .target(
            name: "DeploymentTargetLocalhost",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .target(name: "ApodiniDeployBuildSupport"),
                .target(name: "DeploymentTargetLocalhostCommon"),
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
            name: "DeploymentTargetLocalhostRuntimeSupport",
            dependencies: [
                .target(name: "DeploymentTargetLocalhostCommon"),
                .target(name: "ApodiniDeployRuntimeSupport")
            ]
        ),
        
        .target(
            name: "DeploymentTargetAWSLambda",
            dependencies: [
                .target(name: "DeploymentTargetAWSLambdaCommon"),
                .target(name: "ApodiniDeployBuildSupport"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "SotoLambda", package: "soto"),
                .product(name: "SotoApiGatewayV2", package: "soto"),
                .product(name: "SotoIAM", package: "soto"),
                .product(name: "SotoSTS", package: "soto"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit")
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
                //.product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "VaporAWSLambdaRuntime", package: "vapor-aws-lambda-runtime")
            ]
        )
    ]
)
