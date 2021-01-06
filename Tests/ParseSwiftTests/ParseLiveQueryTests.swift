//
//  ParseLiveQueryTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/3/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseLiveQueryTests: XCTestCase {
    struct GameScore: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int = 0

        //custom initializer
        init(score: Int) {
            self.score = score
        }

        init(objectId: String?) {
            self.objectId = objectId
        }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        try? KeychainStore.shared.deleteAll()
        try? ParseStorage.shared.deleteAll()
    }
/*
    func testSubscribe() throws {
        if #available(iOS 13.0, *) {
            let query = GameScore.query("score" > 9)
            guard let subscription = query.subscribe else {
                return
            }

            let expectation1 = XCTestExpectation(description: "Fetch user1")
            subscription.handleEvent { query, score in
                print(query)
                print(score)
                expectation1.fulfill()
            }
            //let subscription = Subscription(query: query)
            //let liveQuery = ParseLiveQuery()!
            //let subscribed = try liveQuery.subscribe(query, handler: subscription)

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                try? query.unsubscribe()
            }

            wait(for: [expectation1], timeout: 50.0)
        } else {
            // Fallback on earlier versions
        }
    }*/
}
