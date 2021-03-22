//
//  LiveQuerySocket.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/31/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//
#if !os(Linux) && !os(Android)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
final class LiveQuerySocket: NSObject {
    private var session: URLSession!
    var delegates = [URLSessionWebSocketTask: LiveQuerySocketDelegate]()
    weak var authenticationDelegate: LiveQuerySocketDelegate?

    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func createTask(_ url: URL) -> URLSessionWebSocketTask {
        let task = session.webSocketTask(with: url)
        return task
    }

    func closeAll() {
        delegates.forEach { (_, client) -> Void in
            client.close(useDedicatedQueue: false)
        }
        authenticationDelegate = nil
    }
}

// MARK: Status
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    enum Status: String {
        case open
        case closed
    }
}

// MARK: Connect
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    func connect(task: URLSessionWebSocketTask,
                 completion: @escaping (Error?) -> Void) throws {
        let encoded = try ParseCoding.jsonEncoder()
            .encode(StandardMessage(operation: .connect,
                                    additionalProperties: true))
        guard let encodedAsString = String(data: encoded, encoding: .utf8) else {
            return
        }
        task.send(.string(encodedAsString)) { error in
            completion(error)
        }
        self.receive(task)
    }
}

// MARK: Send
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    func send(_ data: Data, task: URLSessionWebSocketTask, completion: @escaping (Error?) -> Void) {
        guard let encodedAsString = String(data: data, encoding: .utf8) else {
            completion(nil)
            return
        }
        task.send(.string(encodedAsString)) { error in
            if error == nil {
                self.receive(task)
            }
            completion(error)
        }
    }
}

// MARK: Receive
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {

    func receive(_ task: URLSessionWebSocketTask) {
        task.receive { result in
            switch result {
            case .success(.string(let message)):
                guard let data = message.data(using: .utf8) else {
                    return
                }
                self.delegates[task]?.received(data)
                self.receive(task)
            case .success(.data(let data)):
                self.delegates[task]?.receivedUnsupported(data, socketMessage: nil)
            case .success(let message):
                self.delegates[task]?.receivedUnsupported(nil, socketMessage: message)
            case .failure(let error):
                let parseError = ParseError(code: .unknownError, message: error.localizedDescription)
                self.delegates[task]?.receivedError(parseError)
            }
        }
    }
}

// MARK: URLSession
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension URLSession {
    static let liveQuery = LiveQuerySocket()
}

// MARK: URLSessionWebSocketDelegate
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        delegates[webSocketTask]?.status(.open)
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        self.delegates.forEach { (_, value) -> Void in
            value.status(.closed)
        }
    }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let authenticationDelegate = authenticationDelegate {
            authenticationDelegate.received(challenge: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    #if !os(watchOS)
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        if let socketTask = task as? URLSessionWebSocketTask {
            if let transactionMetrics = metrics.transactionMetrics.last {
                delegates[socketTask]?.received(transactionMetrics)
            }
        }
    }
    #endif
}
#endif
