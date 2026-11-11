# Security Policy

## Reporting a vulnerability

Please report suspected vulnerabilities privately, using the **Report a vulnerability** button on the Security tab of this repository. If that button is not there, or you would rather not go through GitHub, email david.anderson@excelano.com instead. I aim to respond within seven days.

Please do not open public issues for security problems.

## Supported versions

This repository has no releases; it is supported at its default branch.

## What Fangen can access

Fangen has no network surface. There is no server and no account. Phones exchange game data only through QR codes and `fangen://` links that players hand to each other, and the code makes no network request of any kind. The camera, used only to scan codes, is the one permission the app asks for.

Catches are signed. At the deal, the organizer's phone gives each player an Ed25519 key pair and a certificate for it, signed by a one-time organizer key that is discarded when the deal ends. A player's phone signs a token only when that player is caught or forfeits, and the seeker's phone accepts it only if both signatures verify. A catch therefore cannot be produced without the caught player's phone, and no phone ever holds the full ring. What this does and does not prevent is set out in the threat model at the top of `Packages/FangenCore/Sources/FangenCore/Crypto/Signing.swift`.

## What Fangen stores

Each game a phone has joined is kept in `games.json` in the app's own Application Support directory. The player's private signing key for each game is in the iOS Keychain, readable only while the device is unlocked, on this device only, and never synchronized to iCloud Keychain or backups.
