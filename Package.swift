// swift-tools-version:5.3

import PackageDescription


let package = Package(
    name: "Apodini",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Apodini", targets: ["Apodini"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.35.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.1"),
        .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.2.2"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "2.1.0")
    ],
    targets: [
        .target(
            name: "Apodini",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "Runtime", package: "Runtime"),
                "OpenAPIKit"
            ]
        ),
        .testTarget(
            name: "ApodiniTests",
            dependencies: [
                .target(name: "Apodini"),
                .product(name: "XCTVapor", package: "vapor"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
            ]
        ),
        .target(
            name: "TestWebService",
            dependencies: [
                .target(name: "Apodini")
            ]
        )
    ]
)
