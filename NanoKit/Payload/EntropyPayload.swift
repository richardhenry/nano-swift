//
//  EntropyPayload.swift
//  NanoKit
//
//  Created by Richard Henry on 4/28/24.
//

import Foundation
import NanoCrypto

public struct EntropyPayload: Codable {
    public enum RecipientType: Int, Codable {
        case member = 0
        case virtualMember = 1
    }

    public var recipientType: RecipientType
    public var recipientId: AnyID
    public var ciphertext: LabyrinthPQHPKE.SealedBox

    public enum CodingKeys: String, CodingKey {
        case recipientType = "t"
        case recipientId = "r"
        case ciphertext = "c"
    }
}
