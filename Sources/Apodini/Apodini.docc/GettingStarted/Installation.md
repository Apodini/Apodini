# Installation

Create a new Apodini project or add Apodini to the existing project.

## Overview

An Apodini project is a [Swift Package](https://developer.apple.com/documentation/swift_packages) and its structure and dependencies are managed by the [Swift Package Manager](https://swift.org/package-manager/)

### Create New Project

To create a new standalone package in Xcode, follow this instruction on [package creation](https://developer.apple.com/documentation/xcode/creating_a_standalone_swift_package_with_xcode).

Apodini also offers an example [ApodiniTemplate](https://github.com/Apodini/ApodiniTemplate) repository that can be used as a starting point for an Apodini web service. 

Clone the template repository and you can already run a basic web service with Apodini.

### Add Package Dependency

To use Apodini, the newly created package must declare the root `Apodini` packages as dependencies in its `Package.swift` manifest file.

```swift
dependencies: [
    .package(url: "https://github.com/Apodini/Apodini.git", .branch("develop"))
]
```

### Add Target Dependency
Apodini requires you to add the base package to the target dependencies.

Apodini also follows a modular concept which allows you to add more components by adding multiple **Exporters**.

```swift
targets: [
    .target(
        name: "Your Target",
        dependencies: [
            .product(name: "Apodini", package: "Apodini"),
            .product(name: "ApodiniREST", package: "Apodini"),
            .product(name: "ApodiniOpenAPI", package: "Apodini")
        ])
]‚

```

### Sample Installation

Here is a complete `Package.swift` file for a basic installation of a new Apodini project.

```swift
// swift-tools-version:5.5
import PackageDescription


let package = Package(
    name: "ApodiniTemplate",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "WebService",
            targets: ["WebService"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Apodini/Apodini.git", .upToNextMinor(from: "0.3.0"))
    ],
    targets: [
        .executableTarget(
            name: "WebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniOpenAPI", package: "Apodini")
            ]
        ),
        .testTarget(
            name: "WebServiceTests",
            dependencies: ["WebService"]
        )
    ]
)
```

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
