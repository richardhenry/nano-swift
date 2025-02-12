//
//  ViewModel.swift
//  NanoKit
//
//  Created by Richard Henry on 4/7/24.
//

import Combine
import NanoCore
import NanoKit
import SwiftUI

/// A property wrapper that manages the lifecycle of a view model and provides it with the `DataStore` from the SwiftUI environment.
@propertyWrapper struct ViewModel<Value: ViewModelExpressible>: DynamicProperty {
    @Environment(DataStore.self) private var dataStore
    @State private var wrapper: Wrapper

    var wrappedValue: Value {
        wrapper.wrappedValue
    }

    var projectedValue: Bindable<Value> {
        Bindable(wrapper.wrappedValue)
    }

    init(wrappedValue: Value) {
        self.wrapper = Wrapper(wrappedValue: wrappedValue)
    }

    func update() {
        // This method is called by SwiftUI when the view body is being prepared.
        // It may be called multiple times, but we only care about the initial call.
        // We will perform the initial update and set the dataStore and needsUpdate
        // closure properties on the wrapped value.

        guard !wrapper.isBound else { return }
        wrapper.isBound = true

        wrappedValue.dataStore = dataStore
        wrappedValue.needsUpdate = { [weak wrapper] in
            guard let wrapper else { return }
            DispatchQueue.main.async(qos: .userInteractive, execute: wrapper.update)
        }

        wrapper.update()
    }

    private final class Wrapper {
        var wrappedValue: Value
        var isBound = false
        var currentValue: Value.Result?

        init(wrappedValue: Value) {
            self.wrappedValue = wrappedValue
        }

        func update() {
            // This method dispatches an update to the wrapped value update() method and
            // retains the result. For QueryViewModel, the result will be the cancellable
            // for the db value observation. Other types of view models may return void.

            do {
                currentValue = try wrappedValue.update()
            } catch {
                currentValue = nil
                log(error)
            }
        }
    }
}
