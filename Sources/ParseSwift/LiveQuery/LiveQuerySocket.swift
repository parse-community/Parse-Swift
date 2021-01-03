//
//  LiveQuerySocket.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/31/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
protocol LiveQuerySocketDelegate {
    func receivedError(_ error: ParseError)
    func receivedUnsupported(_ string: String?, socketMessage: URLSessionWebSocketTask.Message?)
    func received(_ data: Data)
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics)
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final class LiveQuerySocket: NSObject {
    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    var delegate: LiveQuerySocketDelegate? {
        willSet {
            if newValue != nil {
                try? connect { _ in }
            } else {
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
    private var isConnecting = false //Parse liveQuery server connected
    private var isConnected = false { //Parse liveQuery server connected
        willSet {
            isConnecting = false
        }
    }
    private var isDisconnectedByUser = false {
        willSet {
            if newValue == true {
                isConnected = false
            }
        }
    }

    override init() {
        super.init()
        
        if ParseConfiguration.liveQuerysServerURL == nil {
            ParseConfiguration.liveQuerysServerURL = ParseConfiguration.serverURL
        }

        guard var components = URLComponents(url: ParseConfiguration.liveQuerysServerURL, resolvingAgainstBaseURL: false) else {
            return
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        ParseConfiguration.liveQuerysServerURL = components.url
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        setupSocket()
    }
    
    func setupSocket() {
        if task != nil {
            return
        }
        self.task = session?.webSocketTask(with: ParseConfiguration.liveQuerysServerURL)
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
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        self.isSocketEstablished = true
        try? connect {_ in}
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
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
    func connect(isUserWantsToConnect: Bool = false, completion: (Error?) -> Void) throws {
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
            let encoded = try ParseCoding.jsonEncoder().encode(StandardMessage(operation: .connect, addStandardKeys: true))
            self.send(encoded) { error in
                if error != nil {
                    isConnecting = false
                }
                completion(error)
            }
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
    func send(_ data: Data, completion: (Error?) -> Void) {
        if !isConnected {
            let error = ParseError(code: .unknownError, message: "LiveQuery: Not connected")
            completion(error)
            return
        }
        self.setupSocket()
        task?.send(.data(data)) { error in
            completion(error)
        }
        self.receive()
    }
}

// MARK: Receive
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    private func receive() {
        guard let task = self.task else {
            return
        }

        task.receive { result in
            switch result {

            case .success(.data(let data)):

                if !self.isConnected {
                    //Check if this is a connected response
                    guard let response = try? ParseCoding.jsonDecoder().decode(ConnectionResponse.self, from: data),
                          response.op == .connected else {
                        //If not connected, shouldn't be receiving anything other than connection response
                        guard let outOfOrderMessage = try? ParseCoding.jsonDecoder().decode(NoBody.self, from: data) else {
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
                            let parseError = ParseError(code: .unknownError, message: "LiveQuery error code: \(error.code) message: \(error.error)")
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

            case .success(.string(let message)):
                self.delegate?.receivedUnsupported(message, socketMessage: nil)
            case .success(let message):
                self.delegate?.receivedUnsupported(nil, socketMessage: message)
            case .failure(let error):
                let parseError = ParseError(code: .unknownError, message: error.localizedDescription)
                self.delegate?.receivedError(parseError)
            }
        }
    }
}
