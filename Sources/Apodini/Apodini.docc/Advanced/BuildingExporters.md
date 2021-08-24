# Building Exporters

Writing a web service with Apodini is easy - as long as there are ``InterfaceExporter``s suitable for your purposes. If that is not the case, you might need to adapt one, or build a new one.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

Implementing an exporter package consists of three tasks. Firstly you have to define the _semantic model_ of your exporter. In this step, you basically gather knowledge about the ``WebService`` defined by the developer using your exporter. Then you analyze this knowledge and decide, how you want to represent the ``WebService`` in your exporter's middleware format. Finally, you end up with an exact description on how the runtime-components of your exporter have to be built so that they behave correctly at runtime. See the article <doc:Semantic-Model> for more details.

The second task is to implement the your runtime-components and the bootstrapping thereof. You use the knowledge on the semantic-model to actually start up the exporter's handling methods. This depends entirely on what your ``InterfaceExporter`` should do. For most exporters, This step involves evaluating endpoints, i.e. ``Handler``s. The `ApodiniExtension` target provides powerful primitives for doing just that. However, before you 

The final task is to implement a ``Configuration`` that registers your ``InterfaceExporter`` implementation with the ``Application`` via ``Application/registerExporter(exporter:)``. See <doc:ExporterConfiguration> for more detail.


The central interface for solving the first and second task is the ``InterfaceExporter``. If you only need a local (i.e. endpoint-based) view of the ``WebService``, you will only need to implement ``InterfaceExporter/export(_:)``. However, if you need structural information about the ``WebService``, ``InterfaceExporter/finishedExporting(_:)-64gse`` and ``WebServiceRoot`` are good points to get started.

> Note: If your exporter's middleware also supports raw data, consider making a special implementation for ``InterfaceExporter/export(blob:)``!

The most important things to consider about an endpoint are its location in the web service (defined e.g. by ``EndpointPathComponents``), its input- and output-type, and its ``CommunicationalPattern``. The latter has a huge influence on how your exporter's runtime-logic is structured as the ``CommunicationalPattern`` defines, how many messages in either direction this logic must be able to handle. All this knowledge should be part of your _semantic model_.

> Tip: See <doc:CommunicationPattern> for more detail on the background of ``CommunicationalPattern``. 


Finally, as a general tip about building an ``InterfaceExporter``. Take inspiration from other implementations! In general, `ApodiniHTTP` is the cleanest implementation, best following the three-step guide outlined above. However, if the challenge in building your specific exporter lies on a specific topic (e.g. incorporation of relationship-information, bidirectional communication, ...), also take a look at the implementation of other exporters that have a focus on this topic. Furthermore, if you encounter any difficulties, do not hesitate to [create and issue](https://github.com/Apodini/Apodini/issues)! The Apodini team will be glad to help you. At the current state of the project, it may well be that smaller internal adaptions are needed to meet your requirements. Also, we are happy about all contributions, in the form of exporters, or internal improvements. Feel free to [create a PR](https://github.com/Apodini/Apodini/pulls) anytime! 


## Topics

### Semantic Model

- <doc:Semantic-Model>

### Runtime Components

If your exporter should be able to actually evaluate ``Handler``s, use the tools provided in the `ApodiniExtension` target and make sure to consider these ``KnowledgeSource``s when building your _semantic model_!

- ``EndpointPathComponents``
- ``CommunicationalPattern``
- ``ResponseType``
- ``EndpointParameters``

### Configuration

- <doc:ExporterConfiguration>
- ``Configuration``
- ``Application``
- ``Application/registerExporter(exporter:)``
