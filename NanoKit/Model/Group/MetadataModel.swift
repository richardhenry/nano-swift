//
//  MetadataModel.swift
//  NanoKit
//
//  Created by Richard Henry on 3/25/24.
//

import Foundation
import GRDB

public struct MetadataModel: Codable, Identifiable, FetchableRecord, PersistableRecord {
    public var id: GroupID
    public var epochId: EpochID

    public static var databaseTableName = "metadata"

    enum CodingKeys: String, CodingKey {
        case id = "metadata_group_id"
        case epochId = "metadata_epoch_id"
    }

    public init(id: GroupID, epochId: EpochID) {
        self.id = id
        self.epochId = epochId
    }

    public static func fetchEpoch(_ db: Database, id: GroupID) throws -> EpochModel {
        try EpochModel.fetchExpect(
            db,
            sql: """
                    SELECT epoch.*
                    FROM metadata
                    INNER JOIN epoch
                        ON metadata_epoch_id = epoch_id
                    WHERE metadata_group_id = ?
                """,
            arguments: [id]
        )
    }
}
