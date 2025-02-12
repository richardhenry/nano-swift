//
//  LoadableProtocol.swift
//  NanoKit
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation

public enum LoadingPhase {
    case loading
    case error
    case ready
}

public protocol Loadable {
    var loadingPhase: LoadingPhase { get }
}
