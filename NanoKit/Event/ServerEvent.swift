//
//  ServerEvent.swift
//  Nano
//
//  Created by Richard Henry on 1/4/24.
//

import Combine
import Foundation
import GRDB
import MessagePack
import NanoCore

public enum ServerEventType: Int, Codable {
    case ok = 0
    case error = 1
    case concurrentBatch = 2
    case serialBatch = 3
    case sessionSecret = 4
    case userRecord = 5
    case userKeyRecord = 6
    case messageRecord = 7
    case groupRecord = 8
    case memberRecord = 9
    case inviteRecord = 10
    case inviteBundle = 11
    case metadataRecord = 12
    case threadSettingRecord = 13
    case groupSettingRecord = 14
    case roleRecord = 15
    case roleTemplateRecord = 16
    case secretSettingRecord = 17
    case cursor = 18
    case groupActivityRecord = 19
    case threadActivityRecord = 20
    case virtualMemberRecord = 21
    case epochBundle = 22
    case secretRecord = 23
    case memberRecoveryBundle = 24
    case epochMacRecord = 25

    public var payloadType: (any ServerEventPayload.Type)? {
        switch self {
        case .concurrentBatch, .serialBatch:
            [ServerEvent].self
        case .error:
            ServerErrorPayload.self
        case .ok:
            nil
        case .sessionSecret:
            SessionSecretPayload.self
        case .userRecord:
            UserPayload.self
        case .userKeyRecord:
            UserKeyPayload.self
        case .messageRecord:
            MessagePayload.self
        case .groupRecord:
            GroupPayload.self
        case .memberRecord:
            MemberPayload.self
        case .inviteRecord:
            InvitePayload.self
        case .inviteBundle:
            InviteBundlePayload.self
        case .metadataRecord:
            MetadataPayload.self
        case .threadSettingRecord:
            ThreadSettingPayload.self
        case .groupSettingRecord:
            GroupSettingPayload.self
        case .roleRecord:
            RolePayload.self
        case .roleTemplateRecord:
            RoleTemplatePayload.self
        case .secretSettingRecord:
            SecretSettingPayload.self
        case .cursor:
            CursorPayload.self
        case .groupActivityRecord:
            GroupActivityPayload.self
        case .threadActivityRecord:
            ThreadActivityPayload.self
        case .virtualMemberRecord:
            VirtualMemberPayload.self
        case .epochBundle:
            EpochBundlePayload.self
        case .secretRecord:
            SecretPayload.self
        case .memberRecoveryBundle:
            MemberRecoveryBundlePayload.self
        case .epochMacRecord:
            EpochMacPayload.self
        }
    }
}

public protocol ServerEventPayload: Decodable {
    static func decode(from event: ServerEvent) throws -> Self
    func handle(eventType: ServerEventType) async throws
}

extension ServerEventPayload {
    public static func decode(from event: ServerEvent) throws -> Self {
        assert(event.eventType.payloadType == self)
        return try MessagePackDecoder().decode(self, from: event.data)
    }
}

public struct ServerEvent: Decodable {
    public struct Result {
        public var event: ServerEvent
        public var payload: ServerEventPayload?

        public var error: ServerError? {
            (payload as? ServerErrorPayload)?.error
        }

        public func payload<T: ServerEventPayload>(as expectedType: T.Type) throws -> T {
            if let payload = payload as? T {
                return payload
            } else {
                throw NanoCore.error(
                    "The payload type does not match. Expected: \(expectedType) Got: \(type(of: payload))"
                )
            }
        }
    }

    public static let resultSubject = PassthroughSubject<Result, Never>()

    public var requestId: RequestID?
    public var eventType: ServerEventType
    public var data: Data {
        get throws {
            try _data ?! error("Missing data.")
        }
    }

    public init(data: Data) throws {
        self = try MessagePackDecoder().decode(Self.self, from: data)
    }

    private var _data: Data?

    enum CodingKeys: String, CodingKey {
        case requestId = "r"
        case eventType = "t"
        case _data = "d"
    }

    @inlinable
    public func decode<T: ServerEventPayload>(as decodingType: T.Type) throws -> T {
        try decodingType.decode(from: self)
    }

    @discardableResult public func handle() async throws -> [Result] {
        log(.info, "Event: \(eventType) - Request ID: \(requestId)")

        let results: [Result]
        let error: ServerError?

        if let payloadType = eventType.payloadType {
            let payload: any ServerEventPayload

            do {
                payload = try payloadType.decode(from: self)
            } catch {
                log(.warning, "Failed to decode: \(_data)")
                throw error
            }

            log(.debug, "Event: \(eventType) - Decoded: \(payload)")

            if let batch = payload as? [ServerEvent] {
                let batchResults: [Result] = try await batch.handle(eventType: eventType)

                if !batchResults.isEmpty {
                    results = batchResults
                } else {
                    results = [Result(event: self)]
                }
            } else {
                try await payload.handle(eventType: eventType)
                results = [Result(event: self, payload: payload)]
            }

            error = (payload as? ServerErrorPayload)?.error
        } else {
            results = [Result(event: self)]
            error = nil
        }

        results.forEach { Self.resultSubject.send($0) }

        if let error = error {
            throw error
        }

        return results
    }
}
