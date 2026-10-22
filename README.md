# Fangen

Fangen is secret tag for a group of friends with iPhones. One person deals the game: their phone builds a secret ring of targets and hands each player a personal QR code to scan. From then on you know only your own target. Catch them in person, and they show you a code from their phone; you scan it, and you take over whoever they were seeking. Last one standing wins, or, in a game with an end date, whoever has the most catches when time runs out.

Games come in two styles. A short game of tag suits a party or a park day: tap your target on the shoulder inside the agreed play area. A long game of missions runs for days, and each new target comes with something to get them to do in person without noticing, such as saying the word "pineapple." A mixed game deals each new target one way or the other at random.

## Why it works without a server

There is no server, no account and no network connection. Everything travels between phones as QR codes, or as `fangen://` links when a code has to go through a group chat. That is possible because the deal signs everything up front. Each player's phone receives its own signing key, certified by a one-time organizer key that the dealing phone discards when the deal ends, so no phone ever holds the full ring. When you are caught, your phone signs a code naming your current target, and the seeker's phone checks the signature before taking over that target. A catch cannot be claimed without the caught player's phone, and nobody can work out who is seeking them.

The game is built to keep phones out of school. Catches happen in person and codes are scanned later, after school or on the weekend, and the app sends no notifications. The rules it shows every player steer play away from schools, homes, cars and workplaces.

Nothing leaves the phone. The camera, used only to scan codes, is the single permission the app asks for.

## Building

Open `Fangen.xcodeproj` in Xcode and run the `Fangen` scheme on an iPhone or the simulator. The project file sets the deployment target, and the app has no third-party dependencies. The simulator has no camera, so Debug builds add a Paste button to the scanner, and a link can also be opened from the command line with `xcrun simctl openurl booted "fangen://…"`.

All game logic lives in the `FangenCore` package under `Packages/FangenCore`: the wire formats, the signatures, the handover state machine and the mission library model. It depends only on Foundation and CryptoKit, so its tests run on a Mac with `swift test` from that directory. They include a full-game simulation that plays many randomized games at every supported group size and checks that the ring stays whole throughout. The app's own tests, which cover QR generation, run with `xcodebuild test -scheme Fangen` against an iPhone simulator.

The mission library is `Fangen/Resources/missions.json`. A test in `FangenCore` loads that file and rejects it if an id repeats or a mission doesn't name its target.

## License

MIT. See [LICENSE](LICENSE). To report a security problem, see [SECURITY.md](SECURITY.md).
