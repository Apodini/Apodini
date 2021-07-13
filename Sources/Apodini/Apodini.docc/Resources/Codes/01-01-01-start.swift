import PackageDescription

let package = Package(
    name: "WebService",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "WebService", targets: ["WebService"])
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
            ]
        )
    ]
)
