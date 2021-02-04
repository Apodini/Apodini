// swift-tools-version:5.3

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
        .target(
            name: "TestWebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini")
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
