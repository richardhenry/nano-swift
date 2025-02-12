//
//  Error.swift
//  Nano
//
//  Created by Richard Henry on 1/4/24.
//

import Foundation

public enum ServerError: Int8, Error, Codable {
    public enum RetryPolicy {
        case shouldRetry
        case shouldNotRetry
        case `default`
    }

    case unknown = 0
    case badRequest = 1
    case forbidden = 2
    case notFound = 3
    case internalServerError = 4
    case updateRequired = 5
    case decodingError = 6
    case validationError = 7
    case unauthorized = 8
    case alreadyExists = 9
    case tooManyRequests = 10

    public var shouldRetry: Bool {
        switch self {
        case .unknown,
            .badRequest,
            .forbidden,
            .notFound,
            .decodingError,
            .validationError,
            .unauthorized,
            .alreadyExists:
            false
        case .internalServerError,
            .updateRequired,
            .tooManyRequests:
            true
        }
    }
}

extension ServerError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .badRequest:
            return "Bad Request"
        case .forbidden:
            return "Forbidden"
        case .notFound:
            return "Not Found"
        case .internalServerError:
            return "Internal Server Error"
        case .updateRequired:
            return "Update Required"
        case .decodingError:
            return "Decoding Error"
        case .validationError:
            return "Validation Error"
        case .unauthorized:
            return "Unauthorized"
        case .alreadyExists:
            return "Already Exists"
        case .tooManyRequests:
            return "Too Many Requests"
        }
    }
}
