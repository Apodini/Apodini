//
//  EmptyComponentTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/2/21.
//

@testable import Apodini
import Runtime
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
        
        let componentSharedSemanticModelBuilder = SharedSemanticModelBuilder(app)
        let componentSyntaxTreeVisitor = SyntaxTreeVisitor(semanticModelBuilders: [componentSharedSemanticModelBuilder])
        EmptyComponent().accept(componentSyntaxTreeVisitor)
        componentSyntaxTreeVisitor.finishParsing()
        XCTAssertEqual(componentSharedSemanticModelBuilder.rootNode.collectAllEndpoints().count, 0)
        
        
        let handlerSharedSemanticModelBuilder = SharedSemanticModelBuilder(app)
        let handlerSyntaxTreeVisitor = SyntaxTreeVisitor(semanticModelBuilders: [handlerSharedSemanticModelBuilder])
        EmptyHandler().accept(handlerSyntaxTreeVisitor)
        handlerSyntaxTreeVisitor.finishParsing()
        XCTAssertEqual(componentSharedSemanticModelBuilder.rootNode.collectAllEndpoints().count, 0)
    }
    
    func testNeverRuntimeErrors() throws {
        XCTAssertRuntimeFailure(NeverComponent().content)
        XCTAssertRuntimeFailure(NeverHandler().handle())
    }
}
