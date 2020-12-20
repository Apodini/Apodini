![document type: proposal](https://apodini.github.io/resources/markdown-labels/document_type_proposal.svg)

# Property Wrapper Ideas

This document serves as a collection of ideas about functionality that should be offered to `Components` using property wrappers.

## Information and Configuration

We could envision a property wrapper that provides access to global information such as configuration and information injected by `Guards` or using Apodini specific functionality such as modfiers or endpoints that support authentication or authentication.

We could envision that the property wrapper procides access to the following information and configuration:
* Retrieve a database
* Retrieve configuration such as the IP address
* The authenticated user

## Request specific information

We could envision that a Apodini developer gets access to request specific information such as:
* All header values (or equivalent for non HTTP requests) assoicated with the current request.
* The URI or HTTP protocol information of the request if it is a HTTP request.
* The body of the request as  `Data`  
