import PackageDescription

let package = Package(
    name: "WebService",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "WebService", targets: ["WebService"])
    ],
    dependencies: [
        .package(url: "https://github.com/Apodini/Apodini.git", .branch("develop"))
    ],
    targets: [
        .target(
            name: "WebService",
            dependencies: [
                .target(name: "ExampleWebService")
            ]
        ),
        .target(
            name: "ExampleWebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniOpenAPI", package: "Apodini")
            ]
        )
    ]
)
