# Apodini Authorization

Formulate Authorization Requirements using the <doc:Metadata> system.

<!--

This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT

-->

## Overview

The goal of `ApodiniAuthorization` is to easily define authentication and authorization requirements for the ``WebService``,
``Component``s and ``Handler``s.

The framework introduces four abstractions to deal with arbitrary authentication and authorization scenarios:

- `AuthenticationScheme`: It implements a dedicated authentication scheme by translation the scheme-specific wire protocol into a type representation (referred to as _AuthenticationInfo_). If applicable, it is used to sanitize and reject malformed user input. `ApodiniAuthorization` ships with two authentication schemes implemented out-of-the-box: `BasicAuthenticationScheme` and `BearerAuthenticationScheme`.
- `Authenticatable`: A user-defined model type that captures all state of the authenticated and authorized instance. For example, it might be some sort of user or token model.
- `AuthenticationVerifier`: It acts upon the output of an `AuthenticationScheme` and instantiates the respective `Authenticatable` instance. Additionally, it performs any required verification steps, e.g., checking the correctness of supplied credentials or validating a cryptographic signature. It may also load additional state from a database, e.g., additional data part of the user model.
- `AuthorizationRequirements`: Those are optionally defined by the user and are evaluated against the output of the `AuthenticationVerifier`. They can be used to define further constraints against the `Authenticatable` instance. For example, a particular endpoint might allow access for administrator users only. By default, `ApodiniAuthorization` provides `Allow`, `Deny` and `Verify` requirements.

Creating authentication and authorization requirements is done via the `Authorize` or `AuthorizeOptionally` Metadata.

Using the `AuthorizationRequirements` or `OptionalAuthorizationRequirements` Metadata, one can supply additional `AuthorizationRequirements` for an already authenticated `Authenticatable`.

Inside a ``Handler`` use the `@Authorized` property to access the authenticated and authorized `Authenticatable` instance.
Your ``Handler`` won't be executed if one or more Authorization Metadata fail. Instead, formatted by the `AuthenticationScheme`,
a respective authentication or authorization error is returned to the user.

Below shows an example of using `ApodiniAuthorization` for authentication a `MyUser` using http basic authentication.
The `MyUserVerifier` uses the credentials provided by the `BasicAuthenticationScheme` to look up the user, verify the credentials
and to load additional state like the name.

```swift
import Apodini
import ApodiniAuthorization
import ApodiniAuthorizationBasicScheme

struct PersonalizedGreeter: Handler {
    @Authorized(MyUser.self) var authorizedUser

    func handle() throws -> String {
        if !authorizedUser.isAuthorized {
            return "Hello World"
        }

        let user = try authorizedUser()
        return "Hello \(user.name)"
    }

    var metadata: Metadata {
        AuthorizeOptionally(MyUser.self, using: BasicAuthenticationScheme(), verifiedBy: MyUserVerifier())
    }
}
```

The next example demonstrates how `AuthorizationRequirements` are declared. It implements a `AdministrationHandler` which is only accessible for users with administration privileges.

```swift
import Apodini
import ApodiniAuthorization
import ApodiniAuthorizationBasicScheme

struct AdministrationHandler: Handler {
    @Authorized(MyUser.self) var authorizedUser

    // ...

    var metadata: Metadata {
        Authorize(MyUser.self, using: BasicAuthenticationScheme(), verifiedBy: MyUserVerifier()) {
            Deny(ifNot: \.isAdministrator)
        }
    }
}
```

### JWT

With the `ApodiniAuthorizationJWT` target we provide out-of-the-box support for JSON Web Tokens (JWTs).

As the first step, use the `JWTSigner` configuration (see <doc:Configuration>) to configure your [JWTKit](https://github.com/vapor/jwt-kit) `JWTSigners`.

Next, create your token model conforming to `JWTAuthenticatable`. You may use any of the [JWTKit](https://github.com/vapor/jwt-kit) provided JWT claims. By conforming to `JWTAuthenticatable` you do not need to specify a `AuthenticationScheme` or `AuthenticationVerifier` when declaring your authorization Metadata.

Lastly `ApodiniAuthorizationJWT` provides additional overloads to the `Verify` and all the other `AuthorizationRequirements` to easily formulate authorization requirements for your JWT claims.

Below shows a complete example of using `ApodiniAuthorizationJWT` for a simple JWT token setup:

```swift
import Apodini
import ApodiniAuthorizationJWT

struct SomeJWTToken: JWTAuthenticatable {
    let exp: ExpirationClaim
    let iss: IssuerClaim

    let username: String?
}

struct PrivateGreeter: Handler {
    @Authorized(SomeJWTToken.self) var authorizedToken

    func handle() throws -> String {
        let token = try authorizedToken()
        return "Hello " + token.username
    }

    var metadata: Metadata {
        Authorize(SomeJWTToken.self) {
            Verify(notExpired: \.exp)
            Verify(issuer: \.iss, is: "https://ase.in.tum.de")

            Deny(ifNil: \.username)
        }
    }
}

struct MyWebService: WebService {
    var content: some Component {
        PrivateGreeter()
    }

    var configuration: Configuration {
        JWTSigner(.hs256(key: "secret"))
    }
}

```


## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
