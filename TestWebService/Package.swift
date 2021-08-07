// swift-tools-version:5.4

import PackageDescription


let package = Package(
    name: "TestWebService",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "TestWebService", targets: ["TestWebService"])
    ],
    dependencies: [
        .package(name: "Apodini", path: "..")
    ],
    targets: [
        .executableTarget(
            name: "TestWebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniVaporSupport", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniGRPC", package: "Apodini"),
                .product(name: "ApodiniProtobuffer", package: "Apodini"),
                .product(name: "ApodiniOpenAPI", package: "Apodini"),
                .product(name: "ApodiniWebSocket", package: "Apodini"),
                .product(name: "ApodiniNotifications", package: "Apodini"),
                .product(name: "ApodiniMigration", package: "Apodini"),
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
