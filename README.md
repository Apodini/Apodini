# Apodini

A declarative, composable server-side Swift framework. 
This is a small prototype of what the Apodini framework could look like.

The DSL is composed of `Component`s. Components uses a similar approach to getting input from a Request as the [Swift Argument Parser](https://github.com/apple/swift-argument-parser) uses for getting input from the command line interface. Similarly to a `run` method in the Swift Argument Parser we have a `handle` method to generate a response from one component. The properties annotated with property wrappers can be filled by the different middleware/protocol implemenations based on the middleware/protocol specific conventions.

The `Component`s can be composed into groups and modified using modifiers to alter thier behaviour.

The current prototype only imlements a `Text` component with no othther functionality then returning a String as part of the `handle` method. You can invision that other components or components developed by users of Apodini could include more sophisticated logic in the `handle` method.

The result of the `handle` method is encoded into a protocol/middleware specific encoding using Vapors's `ResponseEncodable` type.

## Requirements

## Installation/Setup/Integration

## Usage

## Contributing
Contributions to this projects are welcome. Please make sure to read the [contribution guidelines](https://github.com/Apodini/.github/blob/release/CONTRIBUTING.md) first.

## License
This project is licensed under the MIT License. See [License](https://github.com/Apodini/Template-Repository/blob/release/LICENSE) for more information.
