//
//  EventHandler.swift
//  Nano
//
//  Created by Richard Henry on 1/22/24.
//

import Combine
import Foundation
import NanoCore

public final class EventHandler {
    public static let shared = EventHandler()

    public init() {
        Sock.shared.connectSubject
            .sink {
                Task.detached(priority: .high) {
                    do {
                        let events = try await DataStore.shared.read { db in
                            try PendingEvent.fetchAll(db)
                        }

                        for event in events {
                            guard Sock.shared.isConnected else {
                                break
                            }

                            do {
                                try await event.unwrap().send()
                            } catch {
                                log(error)
                            }
                        }
                    } catch {
                        log(error)
                    }
                }
            }
            .store(in: &cancellables)

        Sock.shared.receiveSubject
            .sink { data in
                Task.detached(priority: .high) {
                    let event: ServerEvent

                    do {
                        event = try ServerEvent(data: data)
                    } catch {
                        log(error)
                        return
                    }

                    do {
                        try await self.receiveActor.handle(event)
                    } catch {
                        log(.info, "Discarding event that threw an error: \(event)")
                        log(error)
                    }
                }
            }
            .store(in: &cancellables)

        ServerEvent.resultSubject
            .sink { result in
                Task.detached(priority: .high) {
                    do {
                        try await PendingEvent.process(result: result)
                    } catch {
                        log(error)
                    }
                }
            }
            .store(in: &cancellables)
    }

    private let receiveQueue = DispatchQueue(label: "EventHandler")
    private var cancellables = Set<AnyCancellable>()
    private var receiveActor = ReceiveActor()

    private actor ReceiveActor {
        func handle(_ event: ServerEvent) async throws {
            try await event.handle()
        }
    }
}
