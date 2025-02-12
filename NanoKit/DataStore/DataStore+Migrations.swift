//
//  DataStore+Migrator.swift
//  Nano
//
//  Created by Richard Henry on 1/2/24.
//

import Foundation
import GRDB
import NanoCore

extension DataStore {
    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        log(.debug, "Running migrations.")

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v0") { db in
            try db.create(table: "user") { t in
                t.column("user_id", .text).primaryKey().notNull()
                t.column("user_name", .text).notNull()
                t.column("user_image", .jsonText)
            }

            try db.create(virtualTable: "user_search", using: FTS5()) { t in
                t.synchronize(withTable: "user")
                t.column("user_id")
                t.column("user_name")
            }

            try db.create(table: "user_key") { t in
                t.column("user_key_id", .text).primaryKey().notNull()
                t.column("user_key_signing", .blob).notNull()
                t.column("user_key_timestamp", .integer).notNull()
            }

            try db.create(table: "group") { t in
                t.column("group_id", .text).primaryKey().notNull()
                t.column("group_name", .text).notNull()
                t.column("group_image", .jsonText)
                t.column("group_emoji", .text)
                t.column("group_pending", .boolean).notNull()
                t.column("group_unread", .boolean).notNull()
                t.column("group_unread_count", .integer).notNull()
                t.column("group_badge_timestamp", .integer).notNull()
            }

            try db.create(virtualTable: "group_search", using: FTS5()) { t in
                t.synchronize(withTable: "group")
                t.column("group_id")
                t.column("group_name")
            }

            try db.create(table: "epoch") { t in
                t.column("epoch_id", .text).notNull()
                t.column("epoch_group_id", .text).notNull()
                t.column("epoch_sequence_id", .integer).notNull()
                t.column("epoch_discontiguous", .boolean).notNull()
                t.column("epoch_timestamp", .integer).notNull()
                t.primaryKey(["epoch_group_id", "epoch_id"])
            }

            try db.create(table: "member") { t in
                t.column("member_group_id", .text).notNull()
                t.column("member_user_id", .text).notNull()
                t.column("member_store_key", .blob).notNull()
                t.column("member_store_key_kyber", .blob).notNull()
                t.column("member_auth_key", .blob).notNull()
                t.column("member_state", .integer).notNull()
                t.column("member_timestamp", .integer).notNull()
                t.primaryKey(["member_group_id", "member_user_id"])
            }

            try db.create(
                indexOn: "member",
                columns: ["member_group_id", "member_state", "member_timestamp"]
            )

            try db.create(table: "virtual_member") { t in
                t.column("virtual_member_group_id", .text).notNull()
                t.column("virtual_member_id", .text).notNull()
                t.column("virtual_member_owner_user_id", .text).notNull()
                t.column("virtual_member_store_key", .blob).notNull()
                t.column("virtual_member_store_key_kyber", .blob).notNull()
                t.column("virtual_member_timestamp", .integer).notNull()
                t.primaryKey(["virtual_member_group_id", "virtual_member_id"])
            }

            try db.create(table: "thread") { t in
                t.column("thread_group_id", .text).notNull()
                t.column("thread_id", .text).notNull()
                t.column("thread_subject", .text)
                t.column("thread_unread", .boolean).notNull()
                t.column("thread_unread_count", .integer).notNull().defaults(to: 0)
                t.column("thread_total_count", .integer).notNull().defaults(to: 0)
                t.column("thread_root_message_id", .text)
                t.column("thread_last_message_id", .text)
                t.column("thread_badge_timestamp", .integer).notNull()
                t.primaryKey(["thread_group_id", "thread_id"])
            }

            try db.create(
                indexOn: "thread",
                columns: ["thread_group_id", "thread_badge_timestamp"]
            )

            try db.create(table: "message") { t in
                t.column("message_group_id", .text).notNull()
                t.column("message_id", .text).notNull()
                t.column("message_thread_id", .text).notNull()
                t.column("message_user_id", .text).notNull()
                t.column("message_deleted_by_user_id", .text)
                t.column("message_root", .boolean).notNull()
                t.column("message_text", .text)
                t.column("message_attachments", .jsonText)
                t.column("message_links", .jsonText)
                t.column("message_mentions", .jsonText)
                t.column("message_send_state", .integer).notNull()
                t.column("message_create_timestamp", .integer).notNull()
                t.column("message_edit_timestamp", .integer)
                t.primaryKey(["message_group_id", "message_id"])
            }

            try db.create(
                indexOn: "message",
                columns: ["message_group_id", "message_thread_id", "message_create_timestamp"]
            )

            try db.create(virtualTable: "message_search", using: FTS5()) { t in
                t.synchronize(withTable: "message")
                t.column("message_id")
                t.column("message_group_id")
                t.column("message_thread_id")
                t.column("message_text")
            }

            try db.create(table: "session") { t in
                t.column("session_local_id", .integer).primaryKey().notNull()
                t.column("session_user_id", .text).notNull()
                t.column("session_session_id", .integer).notNull()
                t.column("session_token", .text).notNull()
                t.column("session_timestamp", .integer).notNull()
            }

            try db.create(table: "pending_event") { t in
                t.column("event_request_id", .text).primaryKey().notNull()
                t.column("event_type", .integer).notNull()
                t.column("event_data", .blob)
                t.column("event_timestamp", .integer).notNull().indexed()
            }

            try db.create(table: "invite") { t in
                t.column("invite_token", .blob).primaryKey().notNull()
                t.column("invite_group_id", .text).notNull()
                t.column("invite_virtual_id", .text).notNull()
                t.column("invite_pending", .boolean).notNull()
                t.column("invite_timestamp", .integer).notNull()
                t.column("invite_lifetime", .integer)
            }

            try db.create(table: "role") { t in
                t.column("role_group_id", .text).primaryKey().notNull()
                t.column("role_type", .integer).notNull()
                t.column("role_admin_permissions", .jsonText).notNull()
                t.column("role_member_permissions", .jsonText).notNull()
            }

            try db.create(table: "pending_attachment") { t in
                t.column("attachment_group_id", .text).notNull()
                t.column("attachment_message_id", .text).notNull()
                t.column("attachment_asset_key", .text).notNull()
                t.column("attachment_upload_complete", .boolean).notNull()
                t.primaryKey([
                    "attachment_group_id",
                    "attachment_message_id",
                    "attachment_asset_key",
                ])
            }

            try db.create(table: "reaction") { t in
                t.column("reaction_group_id", .text).notNull()
                t.column("reaction_id", .text).notNull()
                t.column("reaction_thread_id", .text).notNull()
                t.column("reaction_user_id", .text).notNull()
                t.column("reaction_target_id", .text)
                t.column("reaction_base", .text)
                t.column("reaction_variation", .text)
                t.column("reaction_send_state", .integer).notNull()
                t.column("reaction_create_timestamp", .integer).notNull()
                t.column("reaction_edit_timestamp", .integer)
                t.primaryKey(["reaction_group_id", "reaction_id"])
            }

            try db.create(
                indexOn: "reaction",
                columns: [
                    "reaction_group_id",
                    "reaction_thread_id",
                ]
            )

            try db.create(
                indexOn: "reaction",
                columns: [
                    "reaction_group_id",
                    "reaction_target_id",
                ]
            )

            try db.create(table: "cursor") { t in
                t.column("cursor_fetch_type", .integer).notNull()
                t.column("cursor_path", .text).notNull()
                t.column("cursor_start_timestamp", .integer).notNull()
                t.column("cursor_start_id", .text)
                t.column("cursor_end_timestamp", .integer)
                t.column("cursor_end_id", .text)
                t.primaryKey([
                    "cursor_fetch_type",
                    "cursor_path",
                    "cursor_start_timestamp",
                    "cursor_start_id",
                    "cursor_end_timestamp",
                    "cursor_end_id",
                ])
            }

            try db.create(table: "metadata") { t in
                t.column("metadata_group_id", .text).primaryKey().notNull()
                t.column("metadata_epoch_id", .text).notNull()
            }

            try db.create(table: "epoch_dirty") { t in
                t.column("epoch_dirty_group_id", .text).primaryKey().notNull()
                t.column("epoch_dirty_last_epoch_timestamp", .integer)
                t.column("epoch_dirty_timestamp", .integer)
            }

            try db.create(table: "group_setting") { t in
                t.column("group_setting_group_id", .text).notNull()
                t.column("group_setting_type", .integer).notNull()
                t.column("group_setting_optimistic", .boolean).notNull()
                t.column("group_setting_value", .integer).notNull()
                t.primaryKey([
                    "group_setting_group_id",
                    "group_setting_type",
                    "group_setting_optimistic",
                ])
            }

            try db.create(table: "thread_setting") { t in
                t.column("thread_setting_group_id", .text).notNull()
                t.column("thread_setting_thread_id", .text).notNull()
                t.column("thread_setting_type", .integer).notNull()
                t.column("thread_setting_optimistic", .boolean).notNull()
                t.column("thread_setting_value", .integer).notNull()
                t.primaryKey([
                    "thread_setting_group_id",
                    "thread_setting_thread_id",
                    "thread_setting_type",
                    "thread_setting_optimistic",
                ])
            }

            try db.create(table: "secret_setting") { t in
                t.column("secret_setting_type", .integer).notNull()
                t.column("secret_setting_optimistic", .boolean).notNull()
                t.column("secret_setting_value", .jsonText).notNull()
                t.primaryKey(["secret_setting_type", "secret_setting_optimistic"])
            }

            try db.create(table: "group_activity") { t in
                t.column("group_activity_id", .text).primaryKey().notNull()
                t.column("group_activity_dirty", .boolean).notNull()
                t.column("group_activity_timestamp", .integer).notNull()
            }

            try db.create(table: "thread_activity") { t in
                t.column("thread_activity_group_id", .text).notNull()
                t.column("thread_activity_id", .text).notNull()
                t.column("thread_activity_dirty", .boolean).notNull()
                t.column("thread_activity_timestamp", .integer).notNull()
                t.column(
                    literal:
                        "thread_activity_path TEXT GENERATED ALWAYS AS (thread_activity_group_id || ',' || thread_activity_id) STORED"
                )
                t.primaryKey(["thread_activity_group_id", "thread_activity_id"])
            }

            try db.create(table: "epoch_mac") { t in
                t.column("epoch_mac_group_id", .text).notNull()
                t.column("epoch_mac_epoch_id", .text).notNull()
                t.column("epoch_mac_user_id", .text).notNull()
                t.column("epoch_mac_mac", .blob).notNull()
                t.column("epoch_mac_timestamp", .integer).notNull()
                t.primaryKey(["epoch_mac_group_id", "epoch_mac_epoch_id", "epoch_mac_user_id"])
            }
        }

        log(.debug, "Migrations finished.")

        return migrator
    }
}
