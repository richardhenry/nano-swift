//
//  EmojiPickerViewModel.swift
//  Nano
//
//  Created by Richard Henry on 2/21/24.
//

import Foundation
import NanoKit

@Observable final class EmojiPickerViewModel {
    var query = "" {
        didSet {
            if query.isEmpty {
                map = Emoji.map
            } else {
                map = Emoji.map.search(prefix: query)
            }
        }
    }

    var map = Emoji.map
}
