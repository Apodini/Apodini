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
        .package(name: "Apodini", path: ".."),
        .package(name: "ApodiniDeploy", path: "../ApodiniDeploy")
    ],
    targets: [
        .target(
            name: "TestWebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "DeploymentTargetLocalhostRuntimeSupport", package: "ApodiniDeploy"),
                .product(name: "DeploymentTargetAWSLambdaRuntime", package: "ApodiniDeploy"),
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
