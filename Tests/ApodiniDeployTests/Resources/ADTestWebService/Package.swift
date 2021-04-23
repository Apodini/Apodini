// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let apodiniLocation: String = {
    if let path = ProcessInfo.processInfo.environment["LKApodiniSourceRoot"] {
        return path
    } else {
        fatalError("AAARGH at <<<\(FileManager.default.currentDirectoryPath)>>>")
    }
}()

print("apodiniLocation: \(apodiniLocation)")


let package = Package(
    name: "ADTestWebService",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "ADTestWebService", targets: ["ADTestWebService"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "Apodini", path: apodiniLocation)
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ADTestWebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniOpenAPI", package: "Apodini"),
                .product(name: "ApodiniDeploy", package: "Apodini"),
                .product(name: "DeploymentTargetLocalhostRuntime", package: "Apodini")
            ]
        )
    ]
)
