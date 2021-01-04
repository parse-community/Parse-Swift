//
//  LiveQuerySocket.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/31/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
protocol LiveQuerySocketDelegate: AnyObject {
    func connected()
    func receivedError(_ error: ParseError)
    func receivedUnsupported(_ data: Data?, socketMessage: URLSessionWebSocketTask.Message?)
    func received(_ data: Data)
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics)
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final class LiveQuerySocket: NSObject {
    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    var delegate: LiveQuerySocketDelegate? {
        willSet {
            if newValue != nil && isSocketEstablished {
                try? connect { _ in }
            } else if newValue == nil {
                diconnect()
            }
        }
    }
    private var isSocketEstablished = false { //URLSession has an established socket
        willSet {
            if newValue == false {
                isConnected = newValue
            }
        }
    }
    private var isConnecting = false //Parse liveQuery server connecting
    private var isConnected = false { //Parse liveQuery server connected
        willSet {
            isConnecting = false
            if newValue == true {
                self.delegate?.connected()
            }
        }
    }
    private var isDisconnectedByUser = false {
        willSet {
            if newValue == true {
                isConnected = false
            }
        }
    }

    var isLiveQueryConnected: Bool {
        isConnected
    }

    override init() {
        super.init()

        if ParseConfiguration.liveQuerysServerURL == nil {
            ParseConfiguration.liveQuerysServerURL = ParseConfiguration.serverURL
        }

        guard var components = URLComponents(url: ParseConfiguration.liveQuerysServerURL!,
                                             resolvingAgainstBaseURL: false) else {
            return
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        ParseConfiguration.liveQuerysServerURL = components.url
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        setupSocket()
        self.receive()
    }

    func setupSocket() {
        if task != nil {
            return
        }
        self.task = session?.webSocketTask(with: ParseConfiguration.liveQuerysServerURL!)
        task?.resume()
    }
}

// MARK: URLSession
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension URLSession {
    static let liveQuery = LiveQuerySocket()
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        self.isSocketEstablished = true
        try? connect {_ in}
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        self.isSocketEstablished = false
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        if task == self.task {
            if let transactionMetrics = metrics.transactionMetrics.last {
                self.delegate?.receivedMetrics(transactionMetrics)
            }
        }
    }
}

// MARK: Connect
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    func connect(isUserWantsToConnect: Bool = false, completion: @escaping (Error?) -> Void) throws {
        if isUserWantsToConnect {
            isDisconnectedByUser = false
        }
        if isConnected || isDisconnectedByUser {
            completion(nil)
            return
        }
        if isConnecting {
            completion(nil)
            return
        } else {
            isConnecting = true
            let encoded = try ParseCoding.jsonEncoder()
                .encode(StandardMessage(operation: .connect,
                                        addStandardKeys: true))
            guard let encodedAsString = String(data: encoded, encoding: .utf8) else {
                print("Error")
                return
            }
            self.setupSocket()
            self.task?.send(.string(encodedAsString)) { error in
                if error == nil {
                    self.isConnecting = false
                }
                completion(error)
            }
            self.receive()
        }
    }
}

// MARK: Disconnect
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    func diconnect() {
        task?.cancel()
        task = nil
        isDisconnectedByUser = true
    }
}

// MARK: Send
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    func send(_ data: Data, completion: @escaping (Error?) -> Void) {
        if !isConnected {
            let error = ParseError(code: .unknownError, message: "LiveQuery: Not connected")
            completion(error)
            return
        }
        self.setupSocket()
        guard let encodedAsString = String(data: data, encoding: .utf8) else {
            completion(nil)
            return
        }
        task?.send(.string(encodedAsString)) { error in
            completion(error)
        }
        self.receive()
    }
}

// MARK: Receive
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func receive() {
        guard let task = self.task else {
            return
        }

        task.receive { result in
            switch result {

            case .success(.string(let message)):

                guard let data = message.data(using: .utf8) else {
                    return
                }

                if !self.isConnected {
                    //Check if this is a connected response
                    guard let response = try? ParseCoding.jsonDecoder().decode(ConnectionResponse.self, from: data),
                          response.op == .connected else {
                        //If not connected, shouldn't be receiving anything other than connection response
                        guard let outOfOrderMessage = try? ParseCoding
                                .jsonDecoder()
                                .decode(NoBody.self, from: data) else {
                            print("LiveQuery: Received message out of order, but couldn't decode it")
                            self.receive()
                            return
                        }
                        print("LiveQuery: Received message out of order: \(outOfOrderMessage)")
                        self.receive()
                        return
                    }
                    self.isConnected = true
                } else {

                    //Check if this is a error response
                    if let error = try? ParseCoding.jsonDecoder().decode(ErrorResponse.self, from: data) {
                        if !error.reconnect {
                            //Treat this as a user disconnect because the server doesn't want to hear from us anymore
                            self.diconnect()
                            return
                        }
                        guard let parseError = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data) else {
                            //Turn LiveQuery error into ParseError
                            let parseError = ParseError(code: .unknownError,
                                                        // swiftlint:disable:next line_length
                                                        message: "LiveQuery error code: \(error.code) message: \(error.error)")
                            self.delegate?.receivedError(parseError)
                            self.receive()
                            return
                        }
                        self.delegate?.receivedError(parseError)

                    } else {
                        //Delegate all other messages to ParseLiveQuery to interpret
                        self.delegate?.received(data)
                    }
                }
                //Fall through and keep receiving messages
                self.receive()

            case .success(.data(let data)):
                self.delegate?.receivedUnsupported(data, socketMessage: nil)
            case .success(let message):
                self.delegate?.receivedUnsupported(nil, socketMessage: message)
            case .failure(let error):
                let parseError = ParseError(code: .unknownError, message: error.localizedDescription)
                self.delegate?.receivedError(parseError)
            }
        }
    }
}
