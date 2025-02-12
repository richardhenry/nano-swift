//
//  CGSize+AspectRatio.swift
//  NanoKit
//
//  Created by Richard Henry on 2/14/24.
//

import Foundation

extension CGSize {
    public var aspectRatio: CGFloat {
        width / height
    }
}
