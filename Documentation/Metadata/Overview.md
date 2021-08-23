<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

 ![documentation](https://apodini.github.io/resources/markdown-labels/document_type_documentation.svg)

# Metadata

Apodini provides a unified and extensive mechanism to specify Metadata for all different WebService
Components (including the global `WebService` level, individual `Component`s, individual `Handler`s or
on `Content` types used as input or output type for a `Handler`).  
Metadata might be anything that adds certain information to the given context of a specific Component.
Any subsystem can define their own Metadata **Definitions** which then the user can use to **declare**
them on a given component.  
The Declaration is done in a declarative way using a Internal Domain-Specific Language,
referred to as **Metadata DSL**.

The following two guides are provided, one tailored towards users and the other tailored
towards Metadata Providers:

* **[Using the Metadata DSL](User%20Guide.md)**
* **[Providing Metadata Definitions](Provider%20Guide.md)**
