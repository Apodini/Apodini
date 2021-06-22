![document type: documentation](https://apodini.github.io/resources/markdown-labels/document_type_documentation.svg)

# OpenAPI Interface Exporter

This document provides a short introduction to using the [`OpenAPIInterfaceExporter`](https://github.com/Apodini/Apodini/blob/develop/Sources/ApodiniOpenAPI/OpenAPIInterfaceExporter.swift), a static exporter for Apodini.
It can be used to expose an OpenAPI specification (version 3.0.3) for an exported RESTful API, as done by the `RESTInterfaceExporter`.

The following explanatory code snippets are taken from a [sample project](https://github.com/lschlesinger/the-game) created to demonstrate the use of the `OpenAPIInterfaceExporter` within the Apodini framework.

## [OpenAPI Specification](https://swagger.io/specification/)

The OpenAPI Specification (OAS) defines a standard, language-agnostic interface to RESTful APIs which allows both humans and computers to discover and understand the capabilities of the service without access to source code, documentation, or through network traffic inspection.
An OpenAPI definition can then be used by documentation generation tools to display the API, code generation tools to generate servers and clients in various programming languages, testing tools, and many other use cases.

## Usage in Apodini `WebService`

Add `OpenAPI` in combination with `REST` for a working RESTful API with associated OAS.

```swift
import Apodini
import ApodiniREST
import ApodiniOpenAPI

struct TheGameWebService: WebService {
    var content: some Component {
        PlayerComponent()
        GameComponent()
    }

    var configuration: Configuration {
        REST { 
            /// Registers the OpenAPI exporter
            OpenAPI()
        }
    }
}

try TheGameWebService.main()
```

If you run the `TestGameWebService.main()`, the startup log will give you the following output:

```plaintext
2021-02-08T21:10:24+0100 info org.apodini.application : OpenAPI specification served in json format on: /openapi
2021-02-08T21:10:24+0100 info org.apodini.application : Swagger-UI on: /openapi-ui
```

This means that per default a `JSON` representation of the OAS is served at `/openapi`, whereas the [Swagger-UI](https://swagger.io/tools/swagger-ui/) can be viewed at `/openapi-ui`.

## OpenAPI-specific Configuration

Additionally, you can pass configurations to `OpenAPI` in order to specify details of the created OAS document and configure the exporter's behavior.

```swift
    var configuration: Configuration {
        REST { 
            /// Adds configuration to the OpenAPIExporter
            OpenAPI(
                outputFormat: .yaml,
                outputEndpoint: "/docs/openapi",
                swaggerUiEndpoint: "/ui/swagger",
                title: "The Game - Endangered Nature Edition, built with Apodini")
        }
    }
```

This overwrites the default endpoints, changes the output format to `YAML`, and provides a custom title to the OAS document.

## Generating Client SDKs from OpenAPI Specification

The easiest way for creating client SDKs from an OAS document is to use [`swagger-codegen`](https://github.com/swagger-api/swagger-codegen).
There are several possibilities to install `swagger-codegen`. 
On macOS you can simply install it using `brew`:

```shell
brew install swagger-codegen
```

After installing `swagger-codegen`, invoke it as follows, for instance to generate an API client library (i.e., client SDK) for an Angular Typescript client:

```shell
swagger-codegen generate -i OPEN_API_INPUT -l typescript-angular -o OUTPUT_DIR
```

where `OPEN_API_INPUT` is the URL to the OAS document served by your Apodini `WebService`, e.g., `http://localhost:8080/openapi` by default. 

## Providing Customized API Descriptions

If you do not further specify descriptions, the `OpenAPIInterfaceExporter` will create a basic OAS document with predefined defaults.
You may overwrite these by making use of the [`DescriptionModifier`](https://github.com/Apodini/Apodini/blob/develop/Sources/Apodini/Modifier/DescriptionModifier.swift) as well as the [`TagModifier`](https://github.com/Apodini/Apodini/blob/develop/Sources/ApodiniOpenAPI/Modifier/TagModifier.swift) on `Handler` level.

```swift
struct GameComponent: Component {
    @PathParameter
    var gameId: String

    var content: some Component {
        Group("game") {
            GetGames()
                .description("Returns all games.")  // Specify a meaningful description of the endpoint.
                .tags("api-game")  // Specify a list of tags for this endpoint.
            // More handlers below... 
        }
    }
}
```

Restart your Apodini `WebService` after these modifications and you will see the results in the plain OAS document, the Swagger-UI, as well as in generated client SDKs.

## Accessing OpenAPI Specification inside Apodini `WebService` 

In case you want to use the OAS document inside your `WebService`, you may access it as follows:

```swift
// `app` is of type `Apodini.Application`.
let storage = app.storage.get(OpenAPIStorageKey.self)
let document: OpenAPI.Document? = storage?.document  // The OAS document as exported by `OpenAPIInterfaceExporter`. 
```
