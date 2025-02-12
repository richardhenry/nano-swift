//
//  Emoji.swift
//  NanoKit
//
//  Created by Richard Henry on 8/11/21.
//

import Foundation
import NanoCore

/// Represents an emoji character.
public struct Emoji: Hashable, Equatable {
    /// A map of categories to emoji characters.
    public static private(set) var map = Map()

    /// A dictionary of emoji base string to emoji value.
    public static private(set) var lookup = [String: Emoji]()

    /// Asynchronously reads the emoji data from disk and sets the shared static props.
    public static func asyncLoad(qos: DispatchQoS.QoSClass) {
        DispatchQueue.global(qos: qos)
            .async {
                do {
                    try Emoji.load()
                } catch {
                    log(error)
                }
            }
    }

    /// Reads the emoji data from disk and sets the shared static props.
    public static func load() throws {
        guard let url = Bundle.main.url(forResource: "emoji-min", withExtension: "json") else {
            log(.warning, "Emoji data is missing.")
            return
        }

        let data = try Data(contentsOf: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            log(.warning, "Unable to decode emoji json.")
            return
        }

        var map = Map()
        var lookup = [String: Emoji]()

        for (rawCategory, rawEmojiData) in json {
            guard let rawCategoryInt = Int(rawCategory),
                let category = Category(rawValue: rawCategoryInt),
                let rawEmojiArray = rawEmojiData as? [[Any]]
            else {
                log(
                    .warning,
                    "Skipping invalid emoji data: \(rawEmojiData) Category: \(rawCategory)"
                )
                continue
            }

            map[category] = []

            for rawEmoji in rawEmojiArray {
                guard let value = rawEmoji[ifExists: 0] as? String,
                    let skinToneVariations = rawEmoji[ifExists: 1] as? [String],
                    let keywords = rawEmoji[ifExists: 2] as? [String]
                else {
                    log(
                        .warning,
                        "Skipping invalid emoji: \(rawEmoji) In: \(rawEmojiArray) Category: \(rawCategory)"
                    )
                    continue
                }

                // Filter out emoji characters that are not supported on this device.
                guard value.count == 1, value.allSatisfy({ $0.isEmoji }) else {
                    log(
                        .trace,
                        "Filtering out unsupported emoji: \(rawEmoji) In: \(rawEmojiArray) Category: \(rawCategory)"
                    )
                    continue
                }

                let emoji = Emoji(
                    value: value,
                    skinToneVariations: skinToneVariations,
                    keywords: keywords
                )
                map[category]!.append(emoji)
                lookup[emoji.value] = emoji
            }
        }

        Self.map = map
        Self.lookup = lookup

        log(.debug, "Loaded emoji set.")
    }

    // MARK: - Types

    /// A map of emoji categories to ordered emoji.
    public typealias Map = [Category: [Emoji]]

    /// Defines the available emoji categories.
    public enum Category: Int, CaseIterable {
        case smileysAndPeople = 0
        case animalsAndNature = 1
        case foodAndDrink = 2
        case activity = 3
        case travelAndPlaces = 4
        case objects = 5
        case symbols = 6
        case flags = 7

        /// The localized name for this category.
        public var localizedName: String {
            switch self {
            case .smileysAndPeople:
                return String(localized: "Smileys & People")
            case .animalsAndNature:
                return String(localized: "Animals & Nature")
            case .foodAndDrink:
                return String(localized: "Food & Drink")
            case .activity:
                return String(localized: "Activity")
            case .travelAndPlaces:
                return String(localized: "Travel & Places")
            case .objects:
                return String(localized: "Objects")
            case .symbols:
                return String(localized: "Symbols")
            case .flags:
                return String(localized: "Flags")
            }
        }
    }

    // MARK: - Emoji

    public let value: String
    public let skinToneVariations: [String]
    public let keywords: [String]

    public func matches(prefix: String) -> Bool {
        for keyword in keywords where keyword.starts(with: prefix) {
            return true
        }

        if prefix.count == 1 {
            if prefix == value {
                return true
            }

            for variation in skinToneVariations where prefix == variation {
                return true
            }
        }

        return false
    }

    @inlinable
    public func render(skinToneVariation: Int?) -> String {
        if let skinToneVariation = skinToneVariation, !skinToneVariations.isEmpty {
            return skinToneVariations[ifExists: skinToneVariation] ?? value
        } else {
            return value
        }
    }
}

extension Emoji: Identifiable {
    public var id: String {
        value
    }
}

extension Emoji.Category: Identifiable {
    public var id: Int {
        rawValue
    }
}

extension Emoji.Map {
    /// A sorted array of the categories that this map contains.
    public var categories: [Emoji.Category] {
        keys.sorted { lhs, rhs in
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Returns a new map where the emoji are filtered against their keywords by the given prefix string.
    public func search(prefix: String?) -> Emoji.Map {
        guard let prefix = prefix?.replacingOccurrences(of: " ", with: "").lowercased(),
            prefix.count > 0
        else {
            return self
        }

        var map = Emoji.Map()

        for (category, emojis) in self {
            let result = emojis.filter { $0.matches(prefix: prefix) }
            if result.count > 0 {
                map[category] = result
            }
        }

        return map
    }
}
