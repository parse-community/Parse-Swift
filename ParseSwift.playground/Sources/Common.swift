import Foundation
import ParseSwift

public func initializeParse(customObjectId: Bool = false) {
    ParseSwift.initialize(applicationId: "applicationId",
                          clientKey: "clientKey",
                          masterKey: "masterKey",
                          serverURL: URL(string: "http://localhost:1337/1")!,
                          allowingCustomObjectIds: customObjectId,
                          usingEqualQueryConstraint: false,
                          usingDataProtectionKeychain: false)
}
