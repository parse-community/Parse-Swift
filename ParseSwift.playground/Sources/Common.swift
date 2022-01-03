import Foundation
import ParseSwift

public func initializeParse() {
    ParseSwift.initialize(applicationId: "applicationId",
                     clientKey: "clientKey",
                     masterKey: "masterKey",
                     serverURL: URL(string: "http://localhost:1337/1")!,
                     isUsingTransactions: false)
}

public func initializeParseCustomObjectId() {
    ParseSwift.initialize(applicationId: "applicationId",
                     clientKey: "clientKey",
                     serverURL: URL(string: "http://localhost:1337/1")!,
                     isAllowingCustomObjectIds: true)
}
