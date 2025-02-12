//
//  MessagePayloadConvertible.swift
//  NanoKit
//
//  Created by Richard Henry on 5/16/24.
//

import Foundation

public enum MessagePayloadConvertible {
    case message(MessageModel)
    case reaction(ReactionModel)

    @inlinable
    public var message: MessageModel? {
        switch self {
        case .message(let message):
            return message
        default:
            return nil
        }
    }

    @inlinable
    public var reaction: ReactionModel? {
        switch self {
        case .reaction(let reaction):
            return reaction
        default:
            return nil
        }
    }

    @inlinable
    public var messageType: MessageType {
        switch self {
        case .message:
            return .message
        case .reaction:
            return .reaction
        }
    }

    @inlinable
    public var groupId: GroupID {
        switch self {
        case .message(let message):
            return message.groupId
        case .reaction(let reaction):
            return reaction.groupId
        }
    }

    @inlinable
    public var id: MessageID {
        switch self {
        case .message(let message):
            return message.id
        case .reaction(let reaction):
            return reaction.id
        }
    }

    @inlinable
    public var threadId: ThreadID {
        switch self {
        case .message(let message):
            return message.threadId
        case .reaction(let reaction):
            return reaction.threadId
        }
    }

    public var userId: UserID {
        switch self {
        case .message(let message):
            return message.userId
        case .reaction(let reaction):
            return reaction.userId
        }
    }
}
