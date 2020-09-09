import Foundation

internal struct ParseConfiguration {
    static var applicationId: String!
    static var masterKey: String?
    static var clientKey: String?
    static var serverURL: URL!
    static var mountPath: String!
}

public func initialize(
    applicationId: String,
    clientKey: String? = nil,
    masterKey: String? = nil,
    serverURL: URL,
    primitiveObjectStore: PrimitiveObjectStore? = nil
) {
    ParseConfiguration.applicationId = applicationId
    ParseConfiguration.clientKey = clientKey
    ParseConfiguration.masterKey = masterKey
    ParseConfiguration.serverURL = serverURL
    ParseConfiguration.mountPath = "/" + serverURL.pathComponents
                                            .filter { $0 != "/" }
                                            .joined(separator: "/")

    ParseStorage.shared.use(primitiveObjectStore ?? CodableInMemoryPrimitiveObjectStore())
    _ = BaseParseInstallation()
}
