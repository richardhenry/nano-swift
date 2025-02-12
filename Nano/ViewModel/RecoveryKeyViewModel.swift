//
//  RecoveryKeyViewModel.swift
//  Nano
//
//  Created by Richard Henry on 4/26/24.
//

import CryptoKit
import Foundation
import GRDB
import NanoCrypto
import NanoKit

@Observable final class RecoveryKeyViewModel: QueryViewModel {
    var dataStore: DataStore = .shared
    var needsUpdate: (() -> Void)?
    var value: CheckByteToken?

    func fetch(_ db: Database) throws -> CheckByteToken? {
        guard let session = try SessionModel.fetchOne(db) else { return nil }
        let ephemeralRecoveryKey: SymmetricKey = try KeychainStorage.shared.get(
            .ephemeralRecoveryKey(session.userId)
        )
        return try CheckByteToken(symmetricKey: ephemeralRecoveryKey)
    }
}
