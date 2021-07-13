# Parse CLI arguments in the WebService

Parse CLI arguments in the WebService

A common use case in software development are CLI arguments (eg. /run --number=3) that can alter the runtime behavior of a program. They pass information to the executable that triggers a certain functionality or sets a certain option. This allows for greater flexibility of the program. 

## CLI argument parsing with the Swift Argument Parser

With CLI argument parsing in the `WebService` we want to achieve exactly this kind of flexibility. This enables us to change the runtime behavior of the `WebService` even after the source code was already compiled to an executable. 
In order to achieve this, we integrate the `swift-argument-parser` library (https://github.com/apple/swift-argument-parser) into the `WebService`. This library is an officially supported Apple library and offers lots of functionality, but as of now it's still under active development and hasn't gotten to a "stable" v1.0 release yet. The argument parser makes it really easy to parse command line parameters in Swift in a type-safe way with the use of Property wrappers.

First state the dependency in the `Package.swift` like that:

```
dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.4.0"))
]
```

Now, the concept of CLI argument parsing in the Apodini `WebService` can be understood best with a direct code example since the implementation that has to be done by the Apodini developer is really easy and straightforward:

```swift
import Apodini
import ArgumentParser

struct ExampleWebService: WebService {
   @Option
   var hostname: String
 
   @Option
   var port: Int

   var configuration: Configuration {
      HTTPConfiguration(hostname: hostname, port: port)
   }
}
```

The developer is able to state the required CLI-arguments directly in the `WebService` struct, decorated with one of the three argument types (property wrappers): `Argument`, `Option` or `Flag`.
* Arguments are values given by a user and are read in order from first to last. For example, this command is called with three file names as arguments:

`./WebService file1.swift file2.swift file3.swift`

A possible `WebService` implementation that parses these parameters looks like this:

```swift
import Apodini
import ArgumentParser

struct ExampleWebService: WebService {
   @Argument
   var files: [String]
}
```

* Options are named key-value pairs. Keys start with one or two dashes (`-` or `--`), and a user can separate the key and value with an equal sign (`=`) or a space. This example command is called with two options:

`./WebService --count=5 --index 2`

A fitting `WebService` would be the following:

```swift
import Apodini
import ArgumentParser

struct ExampleWebService: WebService {
   @Option 
   var count: Int
   @Option 
   var index: Int
}
```

* Flags are like options, but without a paired value. Instead, their presence indicates a particular value (usually true). This example command is called with two flags:

`./WebService --verbose --strip-whitespace`

A possible `WebService` implementation could look like this (Flags have to specify a default value, mostly this will be `false`):

```swift
import Apodini
import ArgumentParser

struct ExampleWebService: WebService {
   @Flag 
   var verbose: Bool
   @Flag 
   var stripWhitespace: Bool
}
```

In the way we specified the `Argument`, `Option` and `Flag` parameters, these parameters are required. Therefore, they have to be specified during the start of the executable, else the `WebService` will fail with an error message like this: `Error: Missing <value>`.

Of course, the developer can specify default values for all parameters or make them optional, so he/she doesn't have to specify the values at every startup (especially useful for the development process). Similar to the examples above, this sample provides default values for every parameter (either with an actual value or an optional, which defaults to nil):

```swift
import Apodini
import ArgumentParser

struct ExampleWebService: WebService {
   @Argument var files: [String] = []
   @Option var count: Int?
   @Option var index = 0
   @Flag var verbose = false
   @Flag var stripWhitespace = false
}
```

Additionally, the argument parser allows to specify configurations for the respective parameters. This allows for renaming of parameters, inversion name specification for flags, decoding options and much more. An example would be: 

```swift
import Apodini
import ArgumentParser

struct ExampleWebService: WebService {
   @Flag(name: .long)  // Parameter name is the name of the variable
   var stripWhitespace = false
   
   @Flag(name: .short)  // Name of parameter gets shortend to only the first letter
   var verbose = false

   @Option(name: .customLong("count"))  // Specify a name for the parameter ourselves
   var iterationCount: Int

   @Option(name: [.customShort("I"), .long])   // Offer multiple possibilities for the name of the parameter
   var inputFile: String

   @Flag(inversion: .prefixedNo).  // Inversion name is no-index
   var index = true

   @Flag(inversion: .prefixedEnableDisable)   // Name of parameters either enable-required-element or disable-required-element
   var requiredElement: Bool
}
```

This provides only a short excerpt about the capabilities of the Swift Argument Parser. Please refer to the documentation (https://github.com/apple/swift-argument-parser/tree/main/Documentation) for further functionalities.

## Use CLI arguments to alter runtime behavior of the WebService

We know how to specify CLI arguments in the WebService, now it's time to use them to alter the behavior of the `WebService` via the user input.

A very common example is the configuration of the HTTP bindings, so the hostname, port etc. where the `WebService` should listen to. In the following example, the developer specifies two CLI arguments; a hostname, which is a string, and a port, which is an integer. These parameters are then used to create an instance of the `HTTPConfiguration` with the specified bindings. Remember that the entire parsing of the CLI arguments is done by the argument parser, so no need for the developer to check for validity, type etc. The result is a very straightforward code that is easy to write and understand. 
Lastly, don't forget to start the parsing of the CLI arguments via an invocation of the static `main()` function on the `WebService`. This automatically triggers the swift argument parser to read the CLI parameters and then executes the `run()` function of the `WebService` which starts the actual webserver.

```swift
import Apodini
import ArgumentParser

struct ExampleWebService: WebService {
    @Option
    var hostname: String

    @Option
    var port: Int

    var configuration: Configuration {
        HTTPConfiguration(hostname: hostname, port: port)
    }
}

ExampleWebService.main()
```

CLI arguments can also be used for the configuration of exporters (see more details regarding this topic here (https://github.com/Apodini/Apodini/wiki/Configuration-of-Exporters). 
A perfect example is the conditional creation, depending on the user's input, of an OpenAPI specification for the `WebService` done via the associated `OpenAPI` exporter of the `REST` exporter.

```swift
import Apodini
import ApodiniREST
import ApodiniOpenAPI
import ArgumentParser

struct ExampleWebService: WebService {
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

ExampleWebService.main()
```

So, if the user passes the respective flag like `./WebService --generateOpenAPIDocs`, an additional OpenAPI documentation is generated for the exported REST webservice. If no flag is specified, the default `false` value prohibits the generation of the documentation. 

This can also be driven further, so that for example the coding strategy of the exporters is configurable as well. In the following example, the developer can specify if the `REST` exporter should use a `JSON` or `XML` coding strategy (for further details take a look at (https://github.com/Apodini/Apodini/wiki/Configuration-of-Exporters). If, and only if the coding strategy is `JSON`, the exporter configuration DSL allows the `REST` exporter to have an associated `OpenAPI` exporter that generates documentation (please also refer to its own wiki entry). In that case, the endpoint where the documentation is available can also be configured via a CLI parameter.

```swift
import Foundation
import Apodini
import ApodiniREST
import OpenAPI
import SotoXML
import ArgumentParser

struct ExampleWebService: WebService {
    @Argument var useRESTfulXML: Bool
    @Argument var openAPIOutputEndpoint: String

    var configuration: Configuration {
        if useRESTfulXML {
            RESTfulInterfaceExporter(
                encoder:  XMLEncoder(),
                decoder: XMLDecoder()
            )
        } else {
              RESTfulInterfaceExporter(
                  encoder: JSONEncoder(),
                  decoder: JSONDecoder()
              ) {
                  OpenAPIExporter(
                      outputEndpoint: openAPIOutputEndpoint,
                      swaggerUiEndpoint: "/ui/swagger",
                      title: "The Game - Endangered Nature Edition, built with Apodini"
                  )
              }
        }
    }
    // some code for XML coders omitted for simplicity
}

ExampleWebService.main()
```

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
