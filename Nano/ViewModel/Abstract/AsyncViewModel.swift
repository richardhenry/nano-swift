//
//  AsyncViewModel.swift
//  NanoKit
//
//  Created by Richard Henry on 4/4/24.
//

import Combine
import NanoCore
import NanoKit

protocol AsyncViewModel: ViewModelExpressible, Loadable where Result == Void {
    /// The current loading state. The default value should be `LoadingPhase.loading`. The system will update this property for you.
    var loadingPhase: LoadingPhase { get set }

    /// Perform an async fetch. You must implement this method in your view model.
    func fetch() async throws
}

extension AsyncViewModel where Result == Void {
    func update() throws {
        Task {
            do {
                try await fetch()
                loadingPhase = .ready
            } catch {
                log(error)
                loadingPhase = .error
            }
        }
    }
}
