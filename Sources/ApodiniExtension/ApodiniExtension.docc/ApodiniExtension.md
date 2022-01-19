# ``ApodiniExtension``

This target provides helpful tools for building Apodini `InterfaceExporter`s. These types are not relevant for building a `WebService`.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

Building an `InterfaceExporter` consists of three tasks. Building the correct _semantic model_, implementing the runtime-components according to the semantic model and wrapping everything in a `Configuration`. Currently, `ApodiniExtension` only includes support for the second task.

To support this task, `ApodiniExtension` defines a processing pipeline that defines default solutions for decoding and processing requests, evaluating `Handler`s and transforming results. This pipeline exists in a function/`EventLoopFuture` based version and an `AsyncSequence` based version. The former only allows for processing a single request to yield a single response. This corresponds to a `CommunicationalPattern/requestResponse`. `AsyncSequence` can handle an arbitrary amount of incoming and outgoing messages, thus allowing to write pipelines for any communicational pattern. This target defines extensions for both types to enable usage of the various protocols and types defined below.

With these primitives we can easily define handler-closures as this one from `ApodiniHTTP`, which is based on Vapor:

```swift
func buildRequestResponseClosure<H: Handler>(for endpoint: Endpoint<H>) ->
    (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> {
    let defaultValues = endpoint[DefaultValueStore.self]

    let strategy = singleInputDecodingStrategy(for: endpoint)
    
    let transformer = VaporResponseTransformer<H>(configuration.encoder)
        
    let factory = endpoint[DelegateFactory<H>.self]
    
    return { (request: Vapor.Request) in
        let delegate = factory.instance()
        
        return strategy
            .decodeRequest(from: request, with: request.eventLoop)
            .insertDefaults(with: defaultValues)
            .cache()
            .evaluate(on: delegate)
            .transform(using: transformer)
    }
}
```


## Topics

### Starting a Pipeline

The begin of the function/`EventLoopFuture` based pipeline usually is the ``DecodingStrategy``. For the `AsyncSequence` version, a ``Subscribable`` in combination with ``AsyncSubscribingSequence`` can be used.

- ``DecodingStrategy``
- ``AsyncSubscribingSequence``
- ``Subscribable``
- ``CompletionCandidate``


### Decoding Requests

The first step in the processing pipeline is transforming the raw request format of your middleware-library into Apodini's `Request`. This is done by a ``DecodingStrategy``.

There exist various types and default implementations of ``DecodingStrategy``. They can be combined and extended by custom ones to fit your use case. Here's an example from `ApodiniHTTP`:

```swift
func singleInputDecodingStrategy(for endpoint: AnyEndpoint) -> AnyDecodingStrategy<Vapor.Request> {
    ParameterTypeSpecific(
        lightweight: LightweightStrategy(),
        path: PathStrategy(),
        content: NumberOfContentParameterAwareStrategy
            .oneIdentityOrAllNamedContentStrategy(configuration.decoder, for: endpoint)
            .transformedToHTTPRequestBasedStrategy()
    )
    .applied(to: endpoint)
    .typeErased
}
```
> Tip: The `ApodiniVaporSupport` target also defines powerful defaults for ``DecodingStrategy`` that work on Vapor's `Request` type.

Next to a ``DecodingStrategy``, the pipeline also requires a ``RequestBasis`` in order to create an ``DecodingRequest``. You can create one quite easily using ``DefaultRequestBasis`` and Vapor's `Request` type also conforms to ``RequestBasis``.

Here is a list of ``DecodingStrategy`` implementations and helper-protocols:

- ``DecodingRequest``


- ``RequestBasis``


- ``DecodingStrategy``
- ``BaseDecodingStrategy``
- ``EndpointDecodingStrategy``

- ``AnyDecodingStrategy``
- ``AnyBaseDecodingStrategy``
- ``AnyEndpointDecodingStrategy``

- ``TransformingStrategy``
- ``TransformingBaseStrategy``
- ``TransformingEndpointStrategy``

- ``NumberOfContentParameterAwareStrategy``
- ``ParameterTypeSpecific``
- ``IdentifierBasedStrategy``
- ``AllNamedStrategy``
- ``AllIdentityStrategy``
- ``InterfaceExporterLegacyStrategy``


- ``ParameterDecodingStrategy``
- ``AnyParameterDecodingStrategy``
- ``TransformingParameterStrategy``

- ``GivenStrategy``
- ``ThrowingStrategy``
- ``PlainPatternStrategy``
- ``NamedChildPatternStrategy``
- ``IndexedNamedChildPatternStrategy``


- ``DecodingPattern``

- ``IdentityPattern``
- ``DynamicNamePattern``
- ``DynamicIndexPattern``


### Process Requests

Once you have decoded the `Request`, there may still be some processing steps to be done before the evaluation.

These steps include the following:

First is the insertion of default values. Usually, this can be done using the ``DefaultValueStore``, which is available via the `Blackboard`. However, if your middleware-library already takes care of inserting default values, you can skip this step.

Second is the validation of parameter-mutability. If your exporter allows for multiple request messages, you have to ensure `Parameter`s marked as `.mutability(.constant)` don't change from one request to an other as long as they are part of the same connection. This can be done using ``MutabilityValidatingRequest``.

Finally you may want to add a `Request`-level cache using ``CachingRequest``. This is advised in general, except your decoding logic is very cheap, e.g. because it is built on a high-level framework that already takes care of caching on this layer. However, in general you must always assume that the `Handler` might decode the same `Parameter` multiple times in one evaluation, causing the `Request/retrieveParameter(_:)` function to be called more than once for the same argument. 

- ``WithRequest``
- ``DefaultValueStore``
- ``DefaultValueStore/DefaultInsertingRequest``
- ``MutabilityValidatingRequest``
- ``CachingRequest``

### Evaluating Endpoints

The evaluation of the now completely processed `Request` is based on Apodini's `Delegate`. Use the `DelegateFactory` from a `Blackboard` to obtain a prepared `Delegate`.

> Warning: Make sure to use a new `DelegateFactory/instance()` for each connection!

If you use a `AsyncSequence` based pipeline and the `Handler` might not close the connection on the first evaluation, you should subscribe to `ObservableObject`s before evaluating the first `Request`. This can be done using `AsyncSequence`'s `subscribe(to:)` extension.

> Note: In that case you'll end up with a pipeline of ``Event``s. They can only be evaluated using the `AsyncSequence` based pipeline.

Finally, you evaluate the `Request` using one of the `evaluate(on:)` extensions. 

- ``Event``
- ``ResponseWithRequest``

### Transforming Results

The final step in the pipeline is transforming the results obtained from the evaluation to one or more responses.

This step is formalized using the ``ResultTransformer`` protocol. Your implementation of the protocol should use your exporter's native output format as ``ResultTransformer/Output``. Make sure to handle errors as well as possible by using ``ErrorHandlingStrategy/graceful(_:)`` or ``ErrorHandlingStrategy/complete(_:)`` instead of ``ErrorHandlingStrategy/abort(_:)``.

- ``ResultTransformer``
- ``ErrorHandlingStrategy``

### Forwarding Errors

It is recommended that `InterfaceExporter`s forward all decoding, evaluation, and result transforming errors using the `Endpoint`s ``ErrorForwarder``. This enables other subsystems to receive these errors and capture them. For example, ApodiniObserve makes use of the forwarded errors to record them for traced `Handler`s.

To support this task, `ApodiniExtension` provides two helpers that can be used in the processing pipeline of an `InterfaceExporter`:

##### Decoding Errors
To forward errors from the entire decoding pipeline (decoding, defaults, caching, etc.), use the ``DecodingErrorForwardingRequest``. `Request` provides a convenience method `forwardDecodingErrors(with:)` which should be added to the processing pipeline directly before the request evaluation step.

##### Evaluation- and Result Transforming Errors
To forward errors from request evaluation and result transforming steps, use the ``ErrorForwardingResultTransformer``. The result transformer wraps an existing result transformer and forwards errors to the passed ``ErrorForwarder``.

##### Other Errors
Errors that are thrown in the pipeline and are not covered by the previous methods can be forwarded manually by passing them to the ``ErrorForwarder/forward(_:)`` method.

#### Example

Here's an example from `ApodiniHTTP`'s interface exporter:

```swift
func buildRequestResponseClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        // wrap the HTTPResponseTransformer to forward errors
        let transformer = ErrorForwardingResultTransformer(
            wrapped: HTTPResponseTransformer<H>(configuration.encoder),
            forwarder: endpoint[ErrorForwarder.self]
        )
        let factory = endpoint[DelegateFactory<H, Exporter>.self]
        return { (request: HTTPRequest) in
            let delegate = factory.instance()
            return strategy
                .decodeRequest(from: request, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .cache()
                // forward decoding errors
                .forwardDecodingErrors(with: endpoint[ErrorForwarder.self])
                .evaluate(on: delegate)
                .transform(using: transformer)
                .map { response in
                    response.setContentLengthForCurrentBody()
                    return response
                }
        }
    }
```

- ``ErrorForwarder``
- ``DecodingErrorForwardingRequest``
- ``ErrorForwardingResultTransformer``
