# nano-swift

Nano is an end-to-end encrypted alternative to Slack/Discord using the [Labyrinth protocol](https://engineering.fb.com/wp-content/uploads/2023/12/TheLabyrinthEncryptedMessageStorageProtocol_12-6-2023.pdf).

This is a proof-of-concept app for iOS and macOS. It’s not available anywhere as a compiled binary, so you must build it yourself and run a server to use it. Feel free to use this code in your own projects under the MIT license.

Code for this project is written in Swift. The UI is mainly built using SwiftUI, although some views are implemented in UIKit and AppKit on iOS and macOS respectively.

The companion server code is written in Rust and lives in [nano-server](https://github.com/richardhenry/nano-server).

## Why Labyrinth?

The state of the art for end-to-end encryption of messages is the [Double Ratchet algorithm](https://signal.org/docs/specifications/doubleratchet/doubleratchet.pdf). But Double Ratchet isn’t the best fit for building a Slack/Discord alternative, because of the expectation that when a new member joins a group they should have access to the history of messages.

Labyrinth is an encrypted message storage protocol described in a whitepaper published by Meta in December 2023 (linked above). While the principal use case for Labyrinth is for backing up one’s own messages, the protocol defines messaging mailboxes in a general way, and it is possible to add an unbounded number of devices to a given mailbox.

In this proof-of-concept, Labyrinth mailboxes are shared between multiple users to achieve end-to-end encrypted messaging where new group members immediately have access to all historical messages. On a regular basis, and whenever a member leaves a group, keys are rotated to protect new messages. This is all achieved without the server having visibility into the content of messages/attachments or custody of the encryption keys (prerequisites for end-to-end encryption).

## Deviations from the Labyrinth Whitepaper

This implementation deviates from the Labyrinth whitepaper in the following ways:
- XChaCha20-Poly1305 is used instead of AES-GCM-Extended.
- Labyrinth HPKE is extended to achieve post-quantum secrecy using CRYSTALS-KYBER-1024. In a manner similar to [PQXDH](https://signal.org/docs/specifications/pqxdh/pqxdh.pdf), the initial keying material incorporates a shared secret from both the X25519 key exchange described in the Labyrinth whitepaper and an additional Kyber key exchange. This implementation of Labyrinth “PQHPKE” can be found in `NanoCrypto/LabyrinthPQHPKE.swift`.

## How to Build

1. Install a recent version of Xcode.
2. Open `Nano.xcodeproj` in Xcode.
3. Edit highlighted placeholders with the URL for the running `nano-server` process. If Xcode isn’t highlighting placeholders that must be replaced, try building which will highlight them as errors.
4. Build and run on an iOS or macOS target.

## Provided Frameworks

This repository contains Swift frameworks that could be extracted and used in another app:
- NanoCore: Some abstract helpers for high precision timestamps, logging, and other things.
- NanoCrypto: This is the implementation of all core cryptography algorithms on top of Clibsodium and Ckyber. Depends on NanoCore.
- NanoKit: This framework implements all model and use case functionality independently of the UI. Depends on NanoCrypto and NanoCore.

The following tests are also provided:
- NanoCryptoTests: A high coverage test suite for NanoCrypto.
- NanoKitTests: A test suite with coverage for some high risk components in NanoKit.

The primary build target is Nano (a cross-platform SwiftUI app). iOS-only code lives in Nano-iOS, and Mac-only code lives in Nano-Mac. The NanoNotificationService target is an iOS notification service that handles the decryption and rendering of push notifications.

## C Dependencies

The C dependencies for this project are included in this repository:
- Clibsodium: Libsodium is the provider of encryption primitives. CryptoKit was considered, but it does not include a number of required algorithms.
- Ckyber1024: The PQClean implementation of CRYSTALS-KYBER-1024.

## Export Compliance

This software includes cryptography and may be subject to U.S. export control laws and regulations. By downloading or using this software, you agree to comply with all applicable export laws and regulations.

## Disclaimer

This is a proof-of-concept. Use it at your own risk.
