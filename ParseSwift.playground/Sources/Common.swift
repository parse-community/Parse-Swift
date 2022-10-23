import Foundation
import ParseSwift

public func initializeParse(customObjectId: Bool = false) {
    ParseSwift.initialize(applicationId: "applicationId",
                          clientKey: "clientKey",
                          primaryKey: "primaryKey",
                          serverURL: URL(string: "http://localhost:1337/1")!,
                          requiringCustomObjectIds: customObjectId,
                          usingEqualQueryConstraint: false,
                          usingDataProtectionKeychain: false)
}
