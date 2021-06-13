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
        
        @Binding var language: String
        
        init(country: Binding<String?>, language: Binding<String> = .constant("EN")) {
            self._country = country
            self._language = language
        }
        
        func handle() -> String {
            country ?? (language == "DE" ? "Welt" : "World")
        }
    }
    
    struct LocalizerInitializer<R: ResponseTransformable>: DelegatingHandlerInitializer {
        typealias Response = R
        
        func instance<D>(for delegate: D) throws -> SomeHandler<Response> where D: Handler {
            SomeHandler(Localizer<D>(from: delegate))
        }
    }
    
    struct Localizer<H: Handler>: Handler {
        @Parameter var language: String = "EN"
        
        let delegate: Delegate<H>
        
        init(from delegate: H) {
            self.delegate = Delegate(delegate)
        }
        
        func handle() throws -> H.Response {
            try delegate.environmentObject(language)().handle()
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
    @EnvironmentObject var language: String
    
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
        Group("localized") {
            Greeter(country: $optionallySelectedCountry, language: $language)
                .delegated(by: LocalizerInitializer<String>())
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
            REST()
        }
    }
    
    func testUsingRESTExporter() throws {
        let testCollection = TestRESTExporterCollection()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testService.accept(visitor)
        visitor.finishParsing()

        EnvironmentValue(self.featured, \BindingTests.featured).configure(self.app)

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
        
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/localized?language=DE") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertTrue(response.body.string.contains("Welt"))
        }
    }
    
    func testAssertBindingAsPathComponent() throws {
        let testCollection = TestRESTExporterCollection()
        testCollection.configuration.configure(app)
        let builder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
        
        self.failingTestService.accept(visitor)
        XCTAssertRuntimeFailure(builder.finishedRegistration())
    }
}
