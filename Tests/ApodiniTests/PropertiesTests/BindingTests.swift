//
//  BindingTests.swift
//  
//
//  Created by Max Obermeier on 24.02.21.
//

import Foundation

@testable import Apodini
import XCTest
import XCTApodini
import ApodiniREST

final class BindingTests: ApodiniTests, EnvironmentAccessible {
    struct Greeter: Handler {
        @Binding var country: String?
        
        func handle() -> String {
            country ?? "World"
        }
    }
    
    struct BindingPassingComponent: Component {
        @Binding var country: String?
        
        var content: some Component {
            Greeter(country: $country)
        }
    }
    
    struct ReallyOptionalGreeter: Handler {
        @Binding var country: String??
        
        func handle() -> String? {
            if let country = self.country {
                return country ?? "World"
            } else {
                return nil
            }
        }
    }
        
    var featured: String? = "Italy"
    
    @PathParameter var selectedCountry: String
    @Environment(\BindingTests.featured) var featuredCountry
    @Parameter var optionallySelectedCountry: String?
    
    @ComponentBuilder
    var testService: some Component {
        Greeter(country: nil)
        Group("default") {
            Greeter(country: .some("USA"))
        }
        Group("optional") {
            Greeter(country: $optionallySelectedCountry)
        }
        Group("featured") {
            Greeter(country: $featuredCountry)
        }
        Group("country", $selectedCountry) {
            Greeter(country: $selectedCountry.asOptional)
            Group("optional") {
                ReallyOptionalGreeter(country: $selectedCountry.asOptional.asOptional)
            }
        }
    }
    
    @ComponentBuilder
    var failingTestService: some Component {
        Group($featuredCountry) {
            Text("Should fail")
        }
    }
    
    struct TestRESTExporterCollection: ConfigurationCollection {
        var configuration: Configuration {
            _RESTInterfaceExporter()
        }
    }
    
    func testUsingRESTExporter() throws {
        let testCollection = TestRESTExporterCollection()
        let builder = SemanticModelBuilder(app)
        testCollection.configuration.configure(app, builder)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
        testService.accept(visitor)
        visitor.finishParsing()
        
        EnvironmentObject(self.featured, \BindingTests.featured).configure(self.app)

        let selectedCountry = "Germany"
        try app.vapor.app.testable(method: .inMemory).test(.GET, "country/\(selectedCountry)") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertTrue(response.body.string.contains(selectedCountry))
        }
        try app.vapor.app.testable(method: .inMemory).test(.GET, "country/\(selectedCountry)/optional") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertTrue(response.body.string.contains(selectedCountry))
        }
        
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertTrue(response.body.string.contains("World"))
        }
        
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/default") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertTrue(response.body.string.contains("USA"))
        }
        
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/featured") { response in
            XCTAssertEqual(response.status, .ok)
            // swiftlint:disable force_unwrapping
            XCTAssertTrue(response.body.string.contains(featured!))
        }
        
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/optional") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertTrue(response.body.string.contains("World"))
        }
        
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/optional?country=Greece") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertTrue(response.body.string.contains("Greece"))
        }
    }
    
    func testAssertBindingAsPathComponent() throws {
        let testCollection = TestRESTExporterCollection()
        let builder = SemanticModelBuilder(app)
        testCollection.configuration.configure(app, builder)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
        self.failingTestService.accept(visitor)
        XCTAssertRuntimeFailure(builder.finishedRegistration())
    }
}
