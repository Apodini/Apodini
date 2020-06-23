// swift-tools-version:5.2

import PackageDescription


let package = Package(
    name: "Apodini",
    products: [
        .library(name: "Apodini", targets: ["Apodini"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(name: "Apodini"),
        .testTarget(name: "ApodiniTests",
                    dependencies: [
                        .target(name: "Apodini")
                    ])
    ]
)
