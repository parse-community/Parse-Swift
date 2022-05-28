import Foundation
import ParseSwift

public func initializeParse() {
    ParseSwift.initialize(applicationId: "applicationId",
                          clientKey: "clientKey",
                          masterKey: "masterKey",
                          serverURL: URL(string: "https://parse-swift.herokuapp.com/1")!,
                          usingTransactions: false,
                          usingEqualQueryConstraint: false)
}

public func initializeParseCustomObjectId() {
    ParseSwift.initialize(applicationId: "applicationId",
                          clientKey: "clientKey",
                          serverURL: URL(string: "https://parse-swift.herokuapp.com/1")!,
                          allowingCustomObjectIds: true,
                          usingEqualQueryConstraint: false)
}
