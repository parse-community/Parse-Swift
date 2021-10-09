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

final class LiveQuerySocket: NSObject {
    private var session: URLSession!
    var delegates = [URLSessionWebSocketTask: LiveQuerySocketDelegate]()
    var receivingTasks = [URLSessionWebSocketTask: Bool]()
    weak var authenticationDelegate: LiveQuerySocketDelegate?

    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func createTask(_ url: URL, taskDelegate: LiveQuerySocketDelegate) -> URLSessionWebSocketTask {
        let task = session.webSocketTask(with: url)
        delegates[task] = taskDelegate
        receive(task)
        return task
    }

    func removeTaskFromDelegates(_ task: URLSessionWebSocketTask) {
        receivingTasks.removeValue(forKey: task)
        delegates.removeValue(forKey: task)
    }

    func closeAll() {
        delegates.forEach { (_, client) -> Void in
            client.close(useDedicatedQueue: false)
        }
    }
}

// MARK: Status
extension LiveQuerySocket {
    enum Status: String {
        case open
        case closed
    }
}

// MARK: Connect
extension LiveQuerySocket {
    func connect(task: URLSessionWebSocketTask,
                 completion: @escaping (Error?) -> Void) throws {
        let encoded = try ParseCoding.jsonEncoder()
            .encode(StandardMessage(operation: .connect,
                                    additionalProperties: true))
        guard let encodedAsString = String(data: encoded, encoding: .utf8) else {
            let error = ParseError(code: .unknownError,
                                   message: "Couldn't encode connect message: \(encoded)")
            completion(error)
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

// MARK: Send
extension LiveQuerySocket {
    func send(_ data: Data, task: URLSessionWebSocketTask, completion: @escaping (Error?) -> Void) {
        guard let encodedAsString = String(data: data, encoding: .utf8) else {
            completion(nil)
            return
        }
        task.send(.string(encodedAsString)) { error in
            completion(error)
        }
    }
}

// MARK: Receive
extension LiveQuerySocket {

    func receive(_ task: URLSessionWebSocketTask) {
        if receivingTasks[task] != nil {
            // Receive has already been called for this task
            return
        }
        receivingTasks[task] = true
        task.receive { result in
            self.receivingTasks.removeValue(forKey: task)
            switch result {
            case .success(.string(let message)):
                if let data = message.data(using: .utf8) {
                    self.delegates[task]?.received(data)
                } else {
                    let parseError = ParseError(code: .unknownError,
                                                message: "Couldn't encode LiveQuery string as data")
                    self.delegates[task]?.receivedError(parseError)
                }
                self.receive(task)
            case .success(.data(let data)):
                self.delegates[task]?.receivedUnsupported(data, socketMessage: nil)
                self.receive(task)
            case .success(let message):
                self.delegates[task]?.receivedUnsupported(nil, socketMessage: message)
                self.receive(task)
            case .failure(let error):
                self.delegates[task]?.receivedError(error)
            }
        }
    }
}

// MARK: Ping
extension LiveQuerySocket {

    func sendPing(_ task: URLSessionWebSocketTask, pongReceiveHandler: @escaping (Error?) -> Void) {
        task.sendPing(pongReceiveHandler: pongReceiveHandler)
    }
}

// MARK: URLSession
extension URLSession {
    static let liveQuery = LiveQuerySocket()
}

// MARK: URLSessionWebSocketDelegate
extension LiveQuerySocket: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        delegates[webSocketTask]?.status(.open,
                                         closeCode: nil,
                                         reason: nil)
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        delegates[webSocketTask]?.status(.closed,
                                         closeCode: closeCode,
                                         reason: reason)
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
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didFinishCollecting metrics: URLSessionTaskMetrics) {
        if let socketTask = task as? URLSessionWebSocketTask,
           let transactionMetrics = metrics.transactionMetrics.last {
                delegates[socketTask]?.received(transactionMetrics)
        }
    }
    #endif
}
#endif
