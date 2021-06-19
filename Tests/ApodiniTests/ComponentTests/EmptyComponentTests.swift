//
//  EmptyComponentTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/2/21.
//

@testable import Apodini
@_implementationOnly import Runtime
import XCTest
import XCTApodini

class EmptyComponentTests: ApodiniTests {
    private struct NeverComponent: Component {
        typealias Content = Never
    }
    
    private struct NeverHandler: Handler {
        typealias Response = Never
    }
    
    func testEmptyComponent() throws {
        XCTAssertRuntimeFailure(EmptyComponent().content)
        
        let componentSharedSemanticModelBuilder = SemanticModelBuilder(app)
        let componentSyntaxTreeVisitor = SyntaxTreeVisitor(modelBuilder: componentSharedSemanticModelBuilder)
        EmptyComponent().accept(componentSyntaxTreeVisitor)
        componentSyntaxTreeVisitor.finishParsing()
        XCTAssertEqual(componentSharedSemanticModelBuilder.collectedEndpoints.count, 0)
        
        
        let handlerSharedSemanticModelBuilder = SemanticModelBuilder(app)
        let handlerSyntaxTreeVisitor = SyntaxTreeVisitor(modelBuilder: handlerSharedSemanticModelBuilder)
        EmptyHandler().accept(handlerSyntaxTreeVisitor)
        handlerSyntaxTreeVisitor.finishParsing()
        XCTAssertEqual(componentSharedSemanticModelBuilder.collectedEndpoints.count, 0)
    }
    
    func testNeverRuntimeErrors() throws {
        XCTAssertRuntimeFailure(NeverComponent().content)
        XCTAssertRuntimeFailure(NeverHandler().handle())
    }
}
