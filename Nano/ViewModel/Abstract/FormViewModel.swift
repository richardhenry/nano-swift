//
//  FormViewModel.swift
//  Nano
//
//  Created by Richard Henry on 1/17/24.
//

import Combine
import NanoCore
import NanoKit

protocol FormViewModel: ViewModelExpressible, Loadable where Result == Void {
    /// The current form phase.
    ///
    /// You must set the initial value to either `.pending` or `.fetching`.
    ///
    /// If the initial value is `.fetching`, the `performFetch()` method will be called asynchronously for you.
    var formPhase: FormPhase { get set }

    /// Submit the form. You should not provide an implementation of this method.
    func submit()

    /// This method will be called by the view model system before the view body is rendered. You can optionally implement this method in your view model.
    func performFetch() async throws

    /// This method will be called by the view model system when the `submit()` method is called. You should provide an implementation of this method in your view model.
    func performSubmit() async throws

    /// This method will be called by the view model system after submission.
    ///
    /// If this method returns `true`, the `formPhase` will transition to `FormPhase.complete`. If it returns `false`, it will transition to `FormPhase.pending`. If this is a "one shot" form, i.e. a form that is only intended to be submitted once in it's lifetime, then return true.
    ///
    /// You can optionally implement this method in your view model. If you
    func shouldComplete() throws -> Bool
}

enum FormPhase {
    case fetching
    case fetchError
    case pending
    case submitting
    case submitError
    case complete

    var isError: Bool {
        switch self {
        case .fetchError, .submitError:
            return true
        case .fetching, .pending, .submitting, .complete:
            return false
        }
    }

    var isDisabled: Bool {
        switch self {
        case .fetching, .fetchError, .submitting, .complete:
            return true
        case .pending, .submitError:
            return false
        }
    }
}

extension FormViewModel {
    var loadingPhase: LoadingPhase {
        switch formPhase {
        case .fetching, .submitting:
            return .loading
        case .pending, .complete:
            return .ready
        case .fetchError, .submitError:
            return .error
        }
    }

    func update() throws {
        if formPhase == .fetching {
            Task { [self] in
                do {
                    try await performFetch()
                    await MainActor.run {
                        formPhase = .pending
                    }
                } catch {
                    log(error)
                    await MainActor.run {
                        formPhase = .fetchError
                    }
                }
            }
        }
    }

    func submit() {
        guard !formPhase.isDisabled else { return }
        formPhase = .submitting

        Task { [self] in
            do {
                try await performSubmit()
                try await MainActor.run {
                    formPhase = try shouldComplete() ? .complete : .pending
                }
            } catch {
                log(error)
                await MainActor.run {
                    formPhase = .submitError
                }
            }
        }
    }

    func performFetch() async throws {}

    func shouldComplete() throws -> Bool { true }
}
