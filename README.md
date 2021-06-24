# Apodini
[![DOI](https://zenodo.org/badge/274515276.svg)](https://zenodo.org/badge/latestdoi/274515276)
[![codecov](https://codecov.io/gh/apodini/apodini/branch/develop/graph/badge.svg?token=QOAYN4SWRN)](https://codecov.io/gh/apodini/apodini)
[![jazzy](https://raw.githubusercontent.com/Apodini/Apodini/gh-pages/badge.svg)](https://apodini.github.io/Apodini/)
![Build and Test](https://github.com/Apodini/Apodini/workflows/Build%20and%20Test/badge.svg)

A declarative, composable framework to build web services using Swift.

## Getting Started

### Installation

Apodini uses the Swift Package Manager:

Add it as a project-dependency:
```swift
dependencies: [
    .package(url: "https://github.com/Apodini/Apodini.git", .branch("develop"))
]
```

Add the base package and all exporters you want to use to your target:
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

### Hello World

Getting started is really easy:

```swift
import Apodini
import ApodiniREST

struct Greeter: Handler {
    @Parameter var country: String?

    func handle() -> String {
        "Hello, \(country ?? "World")!"
    }
}

struct HelloWorld: WebService {
    var configuration: Configuration {
        REST()
    }

    var content: some Component {
        Greeter()
    }
}

HelloWorld.main()

// http://localhost:8080/v1 -> Hello, World!
// http://localhost:8080/v1?country=Italy -> Hello, Italy!
```

Apodini knows enough about your service to automatically generate OpenAPI docs. Just add the respective exporter:

```swift
import ApodiniOpenAPI
...
struct HelloWorld: WebService {
    var configuration: Configuration {
        REST { 
            OpenAPI()
        }
    }
    ...
}

// JSON definition: http://localhost:8080/openapi
// Swagger UI: http://localhost:8080/openapi-ui
```

With `Binding`s we can re-use `Handler`s in different contexts:
```swift
struct Greeter: Handler {
    @Binding var country: String?

    func handle() -> String {
        "Hello, \(country ?? "World")!"
    }
}

struct HelloWorld: WebService {
    var configuration: Configuration {
        REST { 
            OpenAPI()
        }
    }

    var content: some Component {
        Greeter(country: nil)
            .description("Say 'Hello' to the World.")
        Group("country") {
            CountrySubsystem()
        }
    }
}

struct CountrySubsystem: Component {
    @PathParameter var country: String
    
    var content: some Component {
        Group($country) {
            Greeter(country: Binding<String?>($country))
                .description("Say 'Hello' to a country.")
        }
    }
}

// http://localhost:8080/v1 -> Hello, World!
// http://localhost:8080/v1/country/Italy -> Hello, Italy!
```
Apodini allows the developer to specify CLI-arguments that are passed to the `WebService`. The arguments can for example be used in `Configuration`:

```swift
struct HelloWorld: WebService {
    @Flag(help: "Generate an OpenAPI documentation of the WebService.")
    var generateOpenAPIDocs = false
    
    var configuration: Configuration {
        if(generateOpenAPIDocs) {
            REST { 
                OpenAPI()
            }
        } else {
            REST()
        }
    }
}
```
For further information on how to specify CLI-arguments see [https://github.com/apple/swift-argument-parser](https://github.com/apple/swift-argument-parser)

## Documentation

The framework is in early alpha phase. You can inspect the current development manifestos describing the framework in the [documentation folder](Documentation/)

You can find a generated technical documentation for the different Swift types at [https://apodini.github.io/Apodini](https://apodini.github.io/Apodini)

## Contributing
Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/Apodini/.github/blob/release/CONTRIBUTING.md) first.

## License
This project is licensed under the MIT License. See [License](https://github.com/Apodini/Template-Repository/blob/release/LICENSE) for more information.
