//
//  ParseObjectObservableTests.swift
//  ParseSwift
//
//  Created by Craig Spell on 2/10/26.
//
import XCTest
import SwiftUI
@testable import ParseSwift

@available(macOS 14.0, iOS 17.0, *)
final class ParseObjectObservableTests: XCTestCase {
    
    struct MockObject: ParseObject {
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?
        
        var title: String?
    }
    
    func testAsObservableExtension() {
        let object = MockObject(title: "Test")
        let observable = object.asObservable
        XCTAssertEqual(observable.title, "Test")
    }
    
    func testObservationTriggeredOnPropertyChange() {
        let object = MockObject(title: "Initial")
        let observable = object.asObservable
        
        let expectation = self.expectation(description: "Observation should trigger")
        
            // withObservationTracking is how we manually test @Observable in unit tests
        withObservationTracking {
            _ = observable.title
        } onChange: {
            expectation.fulfill()
        }
        
            // Act: Change the property via dynamic member lookup
        observable.title = "Updated"
        
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(observable.title, "Updated")
    }
}
