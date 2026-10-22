# Security Policy

## Reporting a vulnerability

Please report suspected vulnerabilities privately through GitHub Security Advisories at https://github.com/excelano/fangen/security/advisories/new. If you would rather not use GitHub, email david.anderson@excelano.com instead. I aim to respond within seven days.

Please do not open public issues for security problems.

## Supported versions

The latest release receives security fixes. Older releases are not supported. A repository with no releases is supported at its default branch.

## Security model

**Fangen has no network surface.** There is no server and no account. Phones exchange game data only through QR codes and `fangen://` links that players hand to each other, and the code makes no network request of any kind.

**Catches are signed.** At the deal, the organizer's phone gives each player an Ed25519 key pair and a certificate for it, signed by a one-time organizer key that is discarded when the deal ends. A player's phone signs a token only when that player is caught or forfeits, and the seeker's phone accepts it only if both signatures verify. A catch therefore cannot be produced without the caught player's phone, and no phone ever holds the full ring. What this does and does not prevent is set out in the threat model at the top of `Packages/FangenCore/Sources/FangenCore/Crypto/Signing.swift`.
