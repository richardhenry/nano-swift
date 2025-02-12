//
//  ViewModelExpressible.swift
//  Nano
//
//  Created by Richard Henry on 4/9/24.
//

import Combine
import Foundation
import NanoKit

protocol ViewModelExpressible: AnyObject, Observable {
    associatedtype Result

    /// The current `DataStore` from the SwiftUI environment.
    var dataStore: DataStore { get set }

    /// A closure that will trigger another call to update when called. This value will be nil if the view model is not installed on a view.
    var needsUpdate: (() -> Void)? { get set }

    /// This method will be called immediately before a view body is rendered. You can fetch data in the implementation of this method.
    func update() throws -> Result
}

extension ViewModelExpressible {
    /// A convenience method that returns self wrapped inside a view model.
    func wrapped() -> ViewModel<Self> { ViewModel(wrappedValue: self) }
}
