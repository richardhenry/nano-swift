//
//  ClientEvent.swift
//  Nano
//
//  Created by Richard Henry on 1/21/24.
//

import Combine
import Foundation
import GRDB
import MessagePack
import NanoCore

public enum ClientEventType: Int, Codable {
    case messageCreate = 0
    case groupCreate = 1
    case epochCreate = 2
    case inviteCreate = 3
    case inviteGet = 4
    case inviteAccept = 5
    case metadataUpdate = 6
    case pushRegister = 7
    case threadSettingUpdate = 8
    case groupSettingUpdate = 9
    case roleGet = 10
    case roleUpdate = 11
    case roleTemplateUpdate = 12
    case secretSettingUpdate = 13
    case fetch = 14
    case readStateUpdate = 15
    case memberDelete = 16
    case cancelPersistentFetch = 17
    case roleTemplateApplyAll = 18
    case roleTemplateGet = 19
    case userUpdate = 20
    case epochRangeUpdate = 21
    case messageUpdate = 22
    case messageDelete = 23
    case sessionDelete = 24

    public var payloadType: (any ClientEventPayload.Type)? {
        switch self {
        case .messageCreate:
            MessageUpdatePayload.self
        case .groupCreate:
            GroupCreatePayload.self
        case .epochCreate:
            EpochCreatePayload.self
        case .inviteCreate:
            InviteCreatePayload.self
        case .inviteGet:
            InviteGetPayload.self
        case .inviteAccept:
            InviteAcceptPayload.self
        case .metadataUpdate:
            MetadataPayload.self
        case .pushRegister:
            PushPayload.self
        case .threadSettingUpdate:
            ThreadSettingPayload.self
        case .groupSettingUpdate:
            GroupSettingPayload.self
        case .roleGet:
            MemberPath.self
        case .roleUpdate:
            RoleUpdatePayload.self
        case .roleTemplateUpdate:
            RoleTemplateUpdatePayload.self
        case .secretSettingUpdate:
            SecretSettingPayload.self
        case .fetch:
            FetchRequestPayload.self
        case .readStateUpdate:
            ReadStatePayload.self
        case .memberDelete:
            MemberDeletePayload.self
        case .cancelPersistentFetch:
            FetchKey.self
        case .roleTemplateApplyAll:
            GroupPath.self
        case .roleTemplateGet:
            GroupPath.self
        case .userUpdate:
            UserPayload.self
        case .epochRangeUpdate:
            EpochRangeUpdatePayload.self
        case .messageUpdate:
            MessageUpdatePayload.self
        case .messageDelete:
            MessageDeletePayload.self
        case .sessionDelete:
            nil
        }
    }
}

extension ClientEventType: DatabaseValueConvertible {}

public protocol ClientEventPayload: Codable {
    static func decode(from event: ClientEventConvertible) throws -> Self
}

extension ClientEventPayload {
    public static func decode(from event: ClientEventConvertible) throws -> Self {
        assert(event.eventType.payloadType == self)
        return try MessagePackDecoder()
            .decode(
                self,
                from: event.data ?! error("Unable to decode event with no data: \(event)")
            )
    }
}

public protocol ServerErrorHandler: ClientEventPayload {
    func handleError(
        eventType: ClientEventType,
        error: ServerError
    ) async throws -> ServerError.RetryPolicy
}

public struct ClientEvent: Encodable {
    public var requestId: RequestID
    public var eventType: ClientEventType
    public var data: Data?

    enum CodingKeys: String, CodingKey {
        case requestId = "r"
        case eventType = "t"
        case data = "d"
    }

    public init(eventType: ClientEventType, payload: ClientEventPayload?) throws {
        log(.debug, "Event: \(eventType) - Encoding: \(payload)")
        self.requestId = RequestID()
        self.eventType = eventType
        if let payload {
            self.data = try MessagePackEncoder().encode(payload)
        }
    }

    public init(from convertible: ClientEventConvertible) {
        self.requestId = convertible.requestId
        self.eventType = convertible.eventType
        self.data = convertible.data
    }

    public func encode() throws -> Data {
        try MessagePackEncoder().encode(self)
    }
}

public protocol ClientEventConvertible {
    var requestId: RequestID { get }
    var eventType: ClientEventType { get }
    var data: Data? { get }
}

extension ClientEventConvertible {
    public func unwrap() -> ClientEvent {
        if let self = self as? ClientEvent {
            return self
        } else {
            return ClientEvent(from: self)
        }
    }

    public func result() async throws -> ServerEvent.Result {
        try Task.checkCancellation()

        let result = await Future { promise in
            var cancellable: AnyCancellable?
            cancellable = ServerEvent.resultSubject
                .first { $0.event.requestId == requestId }
                .sink {
                    promise(.success($0))
                    cancellable?.cancel()
                }
        }
        .value

        if let error = result.error {
            throw error
        } else {
            return result
        }
    }

    @discardableResult
    public func result(expect eventType: ServerEventType) async throws -> ServerEvent.Result {
        let result = try await result()
        guard result.event.eventType == eventType else {
            throw error(
                "Unexpected response. Expected: \(eventType) Got: \(result.event.eventType)"
            )
        }
        return result
    }
}

extension ClientEvent: ClientEventConvertible {
    public func send() async throws {
        log(.info, "Event: \(eventType) - Request ID: \(requestId)")
        let encoded = try encode()
        try await Sock.shared.send(encoded)
    }
}
