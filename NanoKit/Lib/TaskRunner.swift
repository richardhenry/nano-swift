//
//  TaskRunner.swift
//  NanoKit
//
//  Created by Richard Henry on 5/2/24.
//

import Combine
import Foundation

public actor TaskRunner<Identifier: Hashable> {
    private var tasks = [Identifier: AnyCancellable]()

    func exists(_ identifier: Identifier) -> Bool {
        tasks[identifier] != nil
    }

    func run(_ identifier: Identifier, task: () -> (AnyCancellable)) {
        tasks[identifier] = task()
    }

    func cancel(_ identifier: Identifier) {
        tasks.removeValue(forKey: identifier)
    }

    func cancelAll() {
        tasks.removeAll()
    }
}
