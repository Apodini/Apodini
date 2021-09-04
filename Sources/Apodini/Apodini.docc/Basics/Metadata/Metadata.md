# Metadata

Map requirements of your web service into the implementation.

<!--

This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT

-->

## Overview

Apodini provides a unified and extensive mechanism to map requirements into the implementation.
The Metadata system deals with the specification and enforcement of requirements.
Metadata is considered any information which is required for the realization/enforcement of a requirement.

Metadata can be declared on all elements of an Apodini web service: ``WebService``, ``Component``, ``Handler`` and ``Content`` types.
The latter one are used as input or output types for a ``Handler``.

In general, Metadata can be anything that adds certain information to the context of a given web service element.
Any subsystem can define their own Metadata **Definitions** which then the user can use to **declare**
them on a given component.  
The Declaration is done in a declarative way using an internal domain-specific language,
referred to as **Metadata DSL**.

## Topics

### Using the Metadata DSL

- <doc:MetadataUserGuide>

### Providing Metadata

- <doc:MetadataProviderGuide>

### Web Service Elements

- ``Component``
- ``Handler``
- ``WebService``
- ``Content``
