// swift-tools-version:5.3

import PackageDescription


let package = Package(
    name: "Apodini",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "TestServer", targets: ["TestServer"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.14.0"),
    ],
    targets: [
        .target(
            name: "Apodini",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(
            name: "ApodiniTests",
            dependencies: [
                .target(name: "Apodini")
            ]
        ),
        .target(
            name: "TestServer",
            dependencies: [
                .target(name: "Apodini")
            ]
        )
    ]
)
