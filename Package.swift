// swift-tools-version:5.3

import PackageDescription


let package = Package(
    name: "Apodini",
    platforms: [
        .iOS(.v13), .macOS(.v10_15)
    ],
    products: [
        .library(name: "Apodini", targets: ["Apodini"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.18.0"),
    ],
    targets: [
        .target(
            name: "Apodini",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio")
            ]
        ),
        .target(
            name: "ApodiniREST",
            dependencies: [
                .target(name: "Apodini")
            ]
        ),
        .target(
            name: "ApodiniGraphQL",
            dependencies: [
                .target(name: "Apodini")
            ]
        ),
        .target(
            name: "ApodiniGRPC",
            dependencies: [
                .target(name: "Apodini")
            ]
        ),
        .target(
            name: "ApodiniWebSocket",
            dependencies: [
                .target(name: "Apodini")
            ]
        ),
        .testTarget(
            name: "ApodiniTests",
            dependencies: [
                .target(name: "Apodini"),
                .target(name: "ApodiniREST"),
                .target(name: "ApodiniGraphQL"),
                .target(name: "ApodiniGRPC"),
                .target(name: "ApodiniWebSocket")
            ]
        )
    ]
)
