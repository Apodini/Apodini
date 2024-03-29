# Auditing

Audit your REST or HTTP web service for best practice compliance.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

Many best practices constrain REST and HTTP API design. These cover topics such as return types, caching, URL path design, and many more. You can use Apodini's APIAuditor to automatically check the compliance of your WebService with these best practices:

```swift
import Apodini
import ApodiniREST
import ApodiniAudit

public struct Example: WebService {
    public var configuration: Configuration { 
        REST {
            APIAuditor()
        }
    }
}
```

Before running the first audit, you need to install Python to run the linguistic audits. Furthermore, run the following command after compiling your WebService to install the required Python packages:

```shell
$ ./Example audit setup-nltk
```

Once you have Python and the dependencies installed, perform an audit as follows:

```shell
$ ./Example audit run
```

The report will show up in the console, and will look something like this:

```
/en/dictionary/entries
  SearchDictionaryHandler
    This handler has too many parameters: 12

/en/dictionary/entries/{entryId}
  DeleteDictionaryEntryHandler
    The deleted resource is not returned
      Consider using Apodini’s standard Delete handler!
[...]
```

The findings are grouped by endpoint and Handler, and include a diagnosis and an optional improvement suggestion.

## Configuring best practices

Many of the best practices can be configured. To e.g. allow an endpoint to have more than 10 parameters, specify a configuration as follows:

```swift
public var configuration: Configuration { 
    REST {
        APIAuditor {
            URLPathSegmentLengthConfiguration(maximumLength: 15)
        }
    }
}
```

You can also specify your own best practices. In the following example, we check that DictionaryEntries are only returned from endpoints with the specified prefixes.

```swift
class RestrictDictionaryEntryResourceBestPractice: BestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .returnType
    static var priority: Priority = .high
    
    private var checkedHandlerNames = [String]()

    var configuration = RestrictDictionaryEntryResource(allowedPrefixes: [])
    
    func check(into audit: Audit, _ app: Application) {
        let handlerName = audit.endpoint[HandlerReflectiveName.self].rawValue
        guard !checkedHandlerNames.contains(handlerName) else {
            return
        }
        
        checkedHandlerNames.append(handlerName)
        
        // Check the return type of the Endpoint
        let typeString = String(describing: audit.endpoint[HandleReturnType.self].type)
        guard typeString.contains("DictionaryEntry") else {
            // If the return type is not DictionaryEntry, we have nothing to check
            return
        }

        // Extract the String version of the Endpoint's path
        let pathString = audit.endpoint.absolutePath.map { segment in
                segment.description
            }
            .joined(separator: "/")
        
        // Check whether the Endpoint's path starts with one of the allowed paths
        let hasValidPrefix = configuration.allowedPrefixes.contains {
            pathString.hasPrefix($0)
        }
        
        if !hasValidPrefix {
            // We record a finding if the path does not start with an allowed prefix
            audit.recordFinding(DictionaryEntryResourceFinding.dictionaryEntryAtIllegalLocation(allowedPrefixes: configuration.allowedPrefixes))
        }
    }
    
    required init() { }
    
    init(configuration: RestrictDictionaryEntryResource) {
        self.configuration = configuration
    }
}

enum DictionaryEntryResourceFinding: Finding {
    case dictionaryEntryAtIllegalLocation(allowedPrefixes: [String])
    
    var diagnosis: String {
        switch self {
        case .dictionaryEntryAtIllegalLocation:
            return "DictionaryEntries may not be served from this Endpoint!"
        }
    }
    
    var suggestion: String? {
        switch self {
        case .dictionaryEntryAtIllegalLocation(let allowedPrefixes):
            return "Consider moving it below one of these paths: \(allowedPrefixes.joined(separator: ", "))"
        }
    }
}

public struct RestrictDictionaryEntryResource: BestPracticeConfiguration {
    public func configure() -> BestPractice {
        RestrictDictionaryEntryResourceBestPractice(configuration: self)
    }
    
    var allowedPrefixes: [String]
    
    public init(allowedPrefixes: [String]) {
        self.allowedPrefixes = allowedPrefixes
    }
}
```

In order to register custom best practices with the auditor, you **must** pass a configuration into the APIAuditor:

```swift
public var configuration: Configuration { 
    REST {
        APIAuditor {
            URLPathSegmentLengthConfiguration(maximumLength: 15)
            RestrictDictionaryEntryResource(allowedPrefixes: ["/en/dictionary", "/de/woerterbuch"])
        }
    }
}
```

## Selecting Best Practices

You have fine-grained control over the set of best practices checked for each `WebService`, `Component`, and `Handler` using the `SelectBestPractices` metadata. You can include or exclude specific best practices, categories like linguistic best practices, or whole scopes like best practices only applying to RESTful APIs.

```swift
import Apodini
import ApodiniREST
import ApodiniAudit

public struct Example: WebService {
    public var configuration: Configuration { 
        REST {
            APIAuditor()
        }
    }

    var content: some Component {
        Group("images") {
            ImageHandler()
        }
        .metadata(SelectBestPractices(.exclude, .caching))
        
        Group("posts") {
            PublicPostHander()
            Group("u") {
                PrivatePostHandler()
            }
            .metadata(SelectBestPractices(.exclude, URLPathSegmentLength.self))
        }
    }
}
```
