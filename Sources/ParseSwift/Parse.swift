import Foundation

internal struct ParseConfiguration {
    static var applicationId: String!
    static var masterKey: String? // swiftlint:disable:this inclusive_language
    static var clientKey: String?
    static var serverURL: URL!
    static var liveQuerysServerURL: URL!
    static var mountPath: String!
    static var isTestingSDK = false //Enable this only for certain tests like ParseFile
}

// swiftlint:disable:next inclusive_language
public func initialize(
    applicationId: String,
    clientKey: String? = nil,
    masterKey: String? = nil,
    serverURL: URL,
    liveQueryServerURL: URL,
    primitiveObjectStore: PrimitiveObjectStore? = nil
) {
    ParseConfiguration.applicationId = applicationId
    ParseConfiguration.clientKey = clientKey
    ParseConfiguration.masterKey = masterKey
    ParseConfiguration.serverURL = serverURL
    ParseConfiguration.liveQuerysServerURL = liveQueryServerURL
    ParseConfiguration.mountPath = "/" + serverURL.pathComponents
                                            .filter { $0 != "/" }
                                            .joined(separator: "/")

    ParseStorage.shared.use(primitiveObjectStore ?? CodableInMemoryPrimitiveObjectStore())
    DispatchQueue.main.async {
        _ = BaseParseInstallation()
    }
}

internal func setupForTesting() {
    ParseConfiguration.isTestingSDK = true
    _ = URLSession.testing
}
