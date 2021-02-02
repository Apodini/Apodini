// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApodiniDeploy",
    platforms: [.macOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "ApodiniDeployBuildSupport", targets: ["ApodiniDeployBuildSupport"]),
        .library(name: "ApodiniDeployRuntimeSupport", targets: ["ApodiniDeployRuntimeSupport"]),
        .executable(name: "DeploymentTargetLocalhost", targets: ["DeploymentTargetLocalhost"]),
        .executable(name: "DeploymentTargetAWSLambda", targets: ["DeploymentTargetAWSLambda"]),
        .library(name: "DeploymentTargetLocalhostRuntimeSupport", targets: ["DeploymentTargetLocalhostRuntimeSupport"]),
        .library(name: "DeploymentTargetAWSLambdaRuntime", targets: ["DeploymentTargetAWSLambdaRuntime"])
        

    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/nerdsupremacist/AssociatedTypeRequirementsKit.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.39.1"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "2.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "0.1.0"),
        .package(url: "https://github.com/vapor-community/vapor-aws-lambda-runtime", .upToNextMajor(from: "0.4.0")),
        .package(url: "https://github.com/soto-project/soto.git", from: "5.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "CApodiniDeployBuildSupport"),
        .target(
            name: "ApodiniDeployBuildSupport",
            dependencies: [
                .target(name: "CApodiniDeployBuildSupport"),
                .product(name: "Logging", package: "swift-log")
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
