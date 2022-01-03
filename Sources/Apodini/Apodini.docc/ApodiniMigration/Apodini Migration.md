<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

#  Apodini Migration

`ApodiniMigration` is a functionality offered by ``Apodini``, that automates client application migration while your Web Service evolves
and introduces breaking compatibility to its consumers. `ApodiniMigration` makes use of two automatically generated documents,
namely API Document that describes the interface of your RESTful API, and a machine-readable migration guide, 
that encapsulates breaking changes between two versions of your ``Apodini`` Web Service. A command-line interface program in 
[`ApodiniMigrator` framework](https://github.com/Apodini/ApodiniMigrator) is able to generate an intermediary client library that contains 
all the required components to establish a client-server communication, automatically generate a machine-readable migration guide, and 
finally automatically migrate the client library.


## Getting started

In order to use `ApodiniMigration`, add ``MigratorConfiguration`` (or simply its ``Migrator`` typealias) into the `configuration` property of your Web Service:

```swift
var configuration: Configuration {
    REST()
    
    Migrator(
        // exports the document of the current version at http://localhost/api-document in `yaml` format
        documentConfig: .export(.endpoint("api-document", format: .yaml))
    )
}
```
``Migrator`` offers two configuration options ``DocumentConfiguration`` and ``MigrationGuideConfiguration`` to export its items 
to either a local `directory` of the web service application or exposing at a specific ``endpoint`` in `json` or `yaml` format. 
Make sure to save the `Document`s of each version, because `ApodiniMigration` requires those in order to generate the migration guide for future versions.
Additionally, `ApodiniMigration` stores by default its items in the application storage of the Web Service, which can be accessed as follows:

```swift
let document = app.storage.get(MigratorDocumentStorageKey.self)
let migrationGuide = app.storage.get(MigrationGuideStorageKey.self)
```

Whenever you want to publish a new version of your ``Apodini`` Web Service, you can configure ``Migrator`` as shown below:

```swift
var configuration: Configuration {
    REST()
    
    Migrator(
        // exports the document of the current version at directory `data` in `json` format
        // `ApodiniMigration` creates intermediary directories if they do not exist,
        // .directory export option might be useful during development to inspect the content
        documentConfig: .export(.directory("./data")),
        // compares the current API with the document stored at `Bundle.module`,
        // and exports the automatically generated migration guide at http://localhost/migration-guide in `yaml` format
        migrationGuideConfig: .compare(
            .resource(.module, fileName: "api_v1.0.0", format: .json),
            export: .endpoint("migration-guide")
        )
    )
}
```
`MigrationGuideConfiguration` also supports reading of the migration guide either from the bundle or a local path, 
e.g. `migrationGuideConfig: .read(.file("./migration_guide.yaml"), export: .endpoint("migration-guide"))`.

If `ApodiniMigrator` fails to derive the correct `TypeInformation` representation for the input and return types of your `Handler`s, you can make use of 
`TypeInformationDefaultConstructor` protocol and conform your `Content` types by introducing their `TypeInformation` representation as below. 
(see [ApodiniTypeInformation](https://github.com/Apodini/ApodiniTypeInformation) to get familiar with `TypeInformation` API).

```swift
extension Event: TypeInformationDefaultConstructor {
    public static func construct() -> TypeInformation {
        .object(
            name: TypeName(Event.self),
            properties: [
                .init(name: "id", type: .scalar(.uuid)),
                .init(name: "title", type: .optional(wrappedValue: .scalar(.string))),
                .init(name: "timeSlots", type: .repeated(element: .scalar(.data))),
                .init(name: "category", type: Category.construct())
            ]
        )
    }
}
```

## Command-line interface

Once `Migrator` is registered in the `configuration` property of the Web Service, it automatically registers a `migrator` subcommand to the web service 
consisting of three subsubcommands, which can start or run your Apodini Web Service:

```console
$ swift run YourWebService migrator --help
OVERVIEW: Root subcommand of `ApodiniMigrator`

Starts or runs an Apodini web service based on the configurations of a subsubcommand

USAGE: your-web-service migrator <subcommand>

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  document (default)      A parsable command for generating the API document of
                          the initial web service version
  read                    A parsable command to export a local migration guide
                          and the API document of the current version
  compare                 A parsable command for generating the migration guide
```

For the initial version of the Web Service `document` subsubcommand can be used as follows to expose the document of the current version at `./data` directory as `yaml`:

```console
$ swift run YourWebService migrator document --doc-directory=./data --doc-format=yaml
info org.apodini.migrator : API Document exported at ./data/api_v1.0.0.yaml in yaml format
```

By default, `migrator` subsubcommands simply start the web service to execute migration related tasks and exit afterwards. If you want to additionally run 
the web service via a `migrator` subsubcommand, include `--run-web-service` flag, e.g.: 

```console
$ swift run YourWebService migrator document --doc-endpoint=api-document --doc-format=yaml --run-web-service
info org.apodini.migrator : API Document served at /api-document in yaml format
notice codes.vapor.application : Server starting on 0.0.0.0:80
```

For the future versions of the Web Service, one can make use of either `read` or `compare` subsubcommands of `migrator` to additionally export the migration guide: 
(Use `swift run YourWebService migrator compare --help` or `swift run YourWebService migrator read --help` to get an overview of the required arguments)

```console
$ swift run YourWebService migrator compare --old-document-path=./api_v1.0.0.yaml \
> --doc-endpoint=api-document --doc-format=yaml --guide-endpoint=migration-guide --run-web-service
info org.apodini.migrator : API Document served at /api-document in yaml format
info org.apodini.migrator : Migration Guide served at /migration-guide in json format
notice codes.vapor.application : Server starting on 0.0.0.0:80
```

By default, configurations provided in source code in `configuration` property of the web service, overwrite the CLI arguments. 
Hence, make sure to use empty `Migrator()` initializer when running or starting the web service via `migrator` subcommand, and use the arguments as presented above. 
Provided with a `Document` and a Migration guide, one can make use of `migrator` CLI (see [example](https://github.com/Apodini/ApodiniMigrator#apodinimigratorexample)) 
to automatically generate or migrate an intermediary client library.

## Migration Guide

Automated generation of the migration guide relies on several identifiers of the elements of your Web Service. In order to track the changes over different version,
`ApodiniMigrator` requires to explicitly introduce an identifier to your `Handler`s via `identified(by:)` modifier:

```swift
var content: some Component {
    Group("events") {
        EventsHandler()
            .identified(by: "getAllEvents")
    }
}
```
If no identifier is provided, `ApodiniMigrator` uses the name of the `Handler` as an identifier. It is advisable to provide descriptive identifiers, since those are
used as the name of the corresponding API calling method in the client library. While you can change any other property in your `Handler`s, e.g. their ordering in `Group`,
their parameters, their response or their operation, `ApodiniMigrator` is still able to classify the changes correctly via the `identifier`. 
Updating the identifier would be registered as a deletion of that `Handler` and addition of a new one.

Several other `identifier`s are used to track your API elements, names of the types identify the models, e.g. `Event`, names of the properties of an object, e.g. `title`,
names of the enumeration cases and names of the parameters. `ApodiniMigrator` uses string backed identifiers for each of the elements of the Web API. 
A match is considered if the identifier of an element has been encountered in both versions of the Web API. Afterwards those elements are compared regarding 
their other properties. If no exact matching has been found in the first iteration, `ApodiniMigrator` employs relaxed constraints to the elements of the same type,
before classifying the affected element as either an addition or deletion. 

One of the applied relaxations involves the usage of [Jaro-Winkler distance](https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance).
Jaro-Winkler distance is a general similarity metric to measure the similarity between two strings by returning a value between 0 and 1, 
where 1 means the compared strings are equal. The similarity metric is based on matching characters being at roughly similar positions, 
while characters at the beginning of a string are weighted more heavily. The unmatched elements of the initial comparison iteration are first labeled as 
either addition or removal candidates. On those candidates `ApodiniMigrator` applies the Jaro-Winkler distance and determines as a match, 
those candidate pairs with the largest similarity value over the limit of 0.5. This heuristic allows `ApodiniMigrator` to detect 
renamings of certain elements, and further compare the matched elements on their additional properties. 
Otherwise the respective elements are registered as added or removed.

For addition of the properties of an object or addition of parameters of an `Handler`, the migration guide includes `json` representations of 
default values, e.g. empty strings, zero numerical values, `null` for optional properties, random boolean values, empty arrays and empty dictionaries. The same
approach is followed for deleted items (fallback values). Update the default or fallback values of the migration guide if you want a specific value to be used 
by the client application in that case. In case that you might need to change the type of a property or a parameter, `ApodiniMigrator` automatically
generates `JavaScript` methods, that handle type conversion at runtime during request and response pairs in the client library.

## Examples

Two versions of an example Apodini Web Service using `Migrator` configuration can be found in [`ApodiniMigratorExample`](https://github.com/Apodini/ApodiniMigratorExample).
An overview on how to use `migrator` CLI to generate and migrate the intermediary client library of the example web service, is given in 
[ApodiniMigrator](https://github.com/Apodini/ApodiniMigrator)
