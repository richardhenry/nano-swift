//
//  Sock.swift
//  Nano
//
//  Created by Richard Henry on 1/21/24.
//

import Combine
import Foundation
import MessagePack
import NanoCore
import Network

public final class Sock {
    public static let shared = Sock()

    public var isConnected: Bool {
        webSocketTask?.closeCode == .invalid
    }

    public let connectSubject = PassthroughSubject<(), Never>()
    public let receiveSubject = PassthroughSubject<Data, Never>()

    public func send(_ data: Data) async throws {
        try Task.checkCancellation()
        try await (webSocketTask ?! error("Not connected.")).send(.data(data))
    }

    // MARK: - Implementation

    private let sessionSubject = CurrentValueSubject<SessionModel?, Never>(nil)

    private let urlSession = URLSession(configuration: .ephemeral)
    private var webSocketTask: URLSessionWebSocketTask?

    private let queue = DispatchQueue(label: "Sock")
    private var cancellables = Set<AnyCancellable>()

    private var pendingConnectTask: Task<(), Error>?
    private var retryCount = 0

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "Sock.monitor")
    private let networkChangeSubject = PassthroughSubject<Void, Never>()

    private var pingTimer: DispatchSourceTimer?

    private var networkStatus: NWPath.Status? {
        didSet {
            guard oldValue != networkStatus else { return }
            log(.debug, "Network status changed: \(networkStatus)")
            networkChangeSubject.send()
        }
    }

    private var networkInterface: NWInterface? {
        didSet {
            guard oldValue != networkInterface else { return }
            log(.debug, "Network interface changed: \(networkInterface)")
            networkChangeSubject.send()
        }
    }

    init() {
        guard !isRunningInTests() else {
            return
        }

        pingTimer = DispatchSource.makeTimerSource(queue: queue)
        pingTimer!.schedule(deadline: .now(), repeating: 8, leeway: .seconds(1))
        pingTimer!
            .setEventHandler { [weak self] in
                self?.maybePing()
            }
        pingTimer!.resume()

        SessionModel.valuePublisher
            .receive(on: queue)
            .catch { _ in Empty<SessionModel?, Never>() }
            .sink { [weak self] session in
                self?.sessionSubject.value = session
                self?.update()
            }
            .store(in: &cancellables)

        #if os(iOS)
        AppState.shared.$isActive
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.update()
            }
            .store(in: &cancellables)
        #endif

        AppState.shared.$isUpdateRequired
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.update()
            }
            .store(in: &cancellables)

        networkChangeSubject
            .debounce(for: .milliseconds(100), scheduler: queue)
            .sink { [weak self] _ in
                self?.reset()
            }
            .store(in: &cancellables)

        #if DEBUG || targetEnvironment(simulator)
        networkStatus = NWPath.Status.satisfied
        #else
        monitor.pathUpdateHandler = { [weak self] path in
            self?.networkStatus = path.status
            self?.networkInterface = path.availableInterfaces.first
        }

        monitor.start(queue: monitorQueue)
        #endif
    }

    public func reset() {
        webSocketTask?.cancel()
        update()
    }

    private func update() {
        if sessionSubject.value != nil, platformValue(iOS: AppState.shared.isActive, macOS: true),
            !AppState.shared.isUpdateRequired, networkStatus == .satisfied
        {
            if !isConnected, pendingConnectTask == nil {
                log(
                    .debug,
                    "Connecting: \(isConnected) \(pendingConnectTask) \(!AppState.shared.isUpdateRequired)"
                )

                pendingConnectTask = Task {
                    log(.debug, "Running connect task.")
                    do {
                        try await connect()
                        log(.debug, "Connected.")
                    } catch {
                        log(error)
                    }
                    pendingConnectTask = nil
                }
            }
        } else {
            if let task = pendingConnectTask {
                task.cancel()
                pendingConnectTask = nil
                log(.debug, "Pending connection cancelled.")
            }

            if let task = webSocketTask {
                task.cancel()
                webSocketTask = nil
                log(.debug, "Disconnected because of state change.")
            }
        }
    }

    private func connect() async throws {
        // The maximum delay of 5 seconds will be reached after 10 retries.
        let delay = retryCount > 0 ? min(pow(1.585, Double(retryCount - 1)) * 0.1, 5) : 0

        log(.debug, "Connecting after delay: \(delay)")
        try await Task.sleep(for: .seconds(delay))

        try Task.checkCancellation()

        let request = Request(
            path: "sock",
            method: .get,
            session: try sessionSubject.value ?! error("Session not found.")
        )
        .urlRequest

        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()

        connectSubject.send()

        Task {
            do {
                try await receive()
            } catch {
                log(error)
                log(.debug, "Disconnected because of error.")
                retryCount += 1
                webSocketTask?.cancel()
                webSocketTask = nil
                update()
            }
        }
    }

    private func receive() async throws {
        while isConnected {
            switch try await webSocketTask?.receive() {
            case .data(let data):
                receiveSubject.send(data)
            case .string(let string):
                log(.warning, "Received unexpected string: \(string)")
            default:
                log(.warning, "Received unexpected value.")
            }

            retryCount = 0
        }
    }

    private func maybePing() {
        guard let task = webSocketTask else { return }
        log(.trace, "Sending ping.")
        task.sendPing { error in
            if let error = error {
                log(error)
            } else {
                log(.trace, "Received pong.")
            }
        }
    }
}
