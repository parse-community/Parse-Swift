//
//  ParseFieldOperationTests.swift
//  ParseSwiftTests
//
//  Created by Damian Van de Kauter on 26/12/2020.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import XCTest
@testable import ParseSwift

class ParseFieldOperationTests: XCTestCase {
    struct GameScore: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score : Int

        //custom initializers
        init(score: Int) {
            self.score = score
        }
    }
    let score = GameScore(score: 10)

    func testFieldOperationConstructors() {
        let container = score.mutationContainer
        XCTAssertNotNil(container)
    }
    
    func testFieldOperationEncoding() {
        /*PFFieldOperation *operation = [[PFFieldOperation alloc] init];
        XCTAssertThrows([operation mergeWithPrevious:nil]);
        XCTAssertThrows([operation mergeWithPrevious:[PFSetOperation setWithValue:@1]]);*/
        
        //How do I use the "mergeWithPrevious"?
        //Point me in a direction
    }
    
    func testFieldOperationMerge() {
        
    }
    
    func testFieldOperationApply() {
        
    }
}
