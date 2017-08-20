import Foundation

internal var _applicationId: String!
internal var _masterKey: String?
internal var _clientKey: String?
internal var _serverURL: URL!
internal var _mountPath: String!

public func initialize(applicationId: String,
                       clientKey: String? = nil,
                       masterKey: String? = nil,
                       serverURL: URL) {
    _applicationId = applicationId
    _clientKey = clientKey
    _masterKey = masterKey
    _serverURL = serverURL
    _mountPath = "/" + serverURL.pathComponents.filter { $0 != "/" }.joined(separator: "/")
}
