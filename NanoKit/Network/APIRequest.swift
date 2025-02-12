//
//  APIRequest.swift
//  Nano
//
//  Created by Richard Henry on 1/4/24.
//

import Foundation
import MessagePack
import NanoCore

public struct APIRequest {
    /// A closure type for implementing custom event handling. Return true if the event was handled, or false to request the default event handling.
    public typealias EventHandler = (ServerEvent) async throws -> (Bool)

    private static let urlSession = URLSession(configuration: .ephemeral)

    public var request: URLRequest
    public var data: Data?

    public init(
        path: any StringProtocol,
        method: HTTPMethod,
        session: SessionModel?,
        payload: Encodable? = nil
    ) throws {
        request = Request(path: path, method: method, session: session).urlRequest
        request.httpMethod = method.rawValue
        if let payload = payload {
            data = try MessagePackEncoder().encode(payload)
            log(.debug, "Preparing to send payload: \(payload)")
        } else {
            data = nil
        }
    }

    public func send(eventHandler: EventHandler? = nil) async throws -> APIResponse {
        try await send(responseType: APIResponse.self, eventHandler: eventHandler)
    }

    public func send<T: Decodable>(
        decoding: T.Type,
        eventHandler: EventHandler? = nil
    ) async throws
        -> APIResponseWrapper<T>
    {
        try await send(responseType: APIResponseWrapper<T>.self, eventHandler: eventHandler)
    }

    private func send<T: APIResponseCompatible>(
        responseType: T.Type,
        eventHandler: EventHandler? = nil
    ) async throws -> T {
        log(.info, "\(request.httpMethod) \(request.url)")

        let (responseData, response): (Data, URLResponse)
        if let data = data {
            (responseData, response) = try await Self.urlSession.upload(for: request, from: data)
        } else {
            (responseData, response) = try await Self.urlSession.data(for: request)
        }

        if let response = response as? HTTPURLResponse {
            log(
                .debug,
                "\(request.httpMethod) \(request.url) Status: \(response.statusCode) Data: \(responseData)"
            )
        }

        let decoded = try MessagePackDecoder().decode(T.self, from: responseData)

        if let events = decoded.events {
            for event in events {
                if try await eventHandler?(event) != true {
                    try await event.handle()
                }
            }
        }

        return decoded
    }
}

public protocol APIResponseCompatible: Decodable {
    var events: [ServerEvent]? { get }
}

public struct APIResponse: APIResponseCompatible {
    public let events: [ServerEvent]?

    enum CodingKeys: String, CodingKey {
        case events = "e"
    }
}

public struct APIResponseWrapper<T: Decodable>: APIResponseCompatible {
    public let value: T?
    public let events: [ServerEvent]?

    enum CodingKeys: String, CodingKey {
        case value = "v"
        case events = "e"
    }
}
