//
//  Query.swift
//  NanoKit
//
//  Created by Richard Henry on 4/7/24.
//

import Foundation
import GRDB

public protocol Query {
    associatedtype Result
    func fetch(_ db: Database) throws -> Result
}
