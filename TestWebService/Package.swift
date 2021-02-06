// swift-tools-version:5.3

import PackageDescription


let package = Package(
    name: "TestWebService",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "TestWebService", targets: ["TestWebService"])
    ],
    dependencies: [
        .package(name: "Apodini", path: "..")
        //.package(name: "ApodiniDeploy", path: "../ApodiniDeploy")
    ],
    targets: [
        .target(
            name: "TestWebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "DeploymentTargetLocalhostRuntimeSupport", package: "Apodini"),
                .product(name: "DeploymentTargetAWSLambdaRuntime", package: "Apodini"),
                //.product(name: "DeploymentTargetLocalhostRuntimeSupport", package: "ApodiniDeploy"),
                //.product(name: "DeploymentTargetAWSLambdaRuntime", package: "ApodiniDeploy"),
                .product(name: "ApodiniVaporSupport", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniGRPC", package: "Apodini"),
                .product(name: "ApodiniProtobuffer", package: "Apodini"),
                .product(name: "ApodiniOpenAPI", package: "Apodini"),
                .product(name: "ApodiniWebSocket", package: "Apodini"),
                .product(name: "ApodiniNotifications", package: "Apodini")
            ]
        ),
        .testTarget(
            name: "TestWebServiceTests",
            dependencies: [
                .target(name: "TestWebService")
            ]
        )
    ]
)
