//
//  UniqueIdentifier.swift
//  NanoKit
//
//  Created by Richard Henry on 1/27/24.
//

import Foundation
import GRDB
import NanoCrypto

public protocol UniqueIdentifier: RawRepresentable, Hashable, Equatable, CustomStringConvertible,
    CustomDebugStringConvertible, Sendable, Codable, DatabaseValueConvertible, SecureBytePackable,
    SizeBytes
where RawValue == UUID {
    func eraseToAny() -> AnyID
}

extension UniqueIdentifier {
    public var uuidString: String {
        rawValue.uuidString
    }

    public var data: Data {
        Swift.withUnsafeBytes(of: rawValue.uuid) { Data($0) }
    }

    public var base64EncodedString: String {
        data.base64EncodedString()
    }

    public init() {
        self.init(rawValue: UUID())!
    }

    public init?(uuidString: String) {
        if let uuid = UUID(uuidString: uuidString) {
            self.init(rawValue: uuid)!
        } else {
            return nil
        }
    }

    public func eraseToAny() -> AnyID {
        return AnyID(rawValue: rawValue)
    }
}

// MARK: CustomStringConvertible conformance
extension UniqueIdentifier {
    public var description: String {
        rawValue.description
    }
}

// MARK: CustomDebugStringConvertible conformance
extension UniqueIdentifier {
    public var debugDescription: String {
        "\(type(of: self))(\(rawValue.uuidString))"
    }
}

// MARK: Codable conformance
extension UniqueIdentifier {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        guard data.count == Self.sizeBytes else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "expected 16 bytes"
            )
        }
        try self.init(rawRepresentation: data)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}

// MARK: DatabaseValueConvertible conformance
extension UniqueIdentifier {
    public var databaseValue: DatabaseValue {
        rawValue.uuidString.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
        if let uuidString = String.fromDatabaseValue(dbValue) {
            return self.init(uuidString: uuidString)
        } else {
            return nil
        }
    }
}

// MARK: SecureBytePackable conformance
extension UniqueIdentifier {
    public init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &uuid) { outBuffer in
            data.withUnsafeBytes { inBuffer in
                precondition(inBuffer.count == Self.sizeBytes)
                outBuffer.copyBytes(from: inBuffer)
            }
        }
        self.init(rawValue: UUID(uuid: uuid))!
    }

    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try Swift.withUnsafeBytes(of: rawValue.uuid, body)
    }
}

// MARK: SizeBytes conformance
extension UniqueIdentifier {
    public static var sizeBytes: Int {
        16
    }
}

// MARK: Zero value

let zeroUuid = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

extension UniqueIdentifier where RawValue == UUID {
    public static var zero: Self {
        self.init(rawValue: zeroUuid)!
    }
}
