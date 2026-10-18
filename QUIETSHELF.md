# QuietShelf Android

QuietShelf is Drake's Android fork of Audiobookshelf Mobile, based on upstream
commit `609f9d644c8390fc662869e08ace18ce4a519b00` (0.14.2-beta).
The original upstream README and GPL license remain in this repository.

Current customizations are the app/package identity, QuietShelf name/icon,
version 0.1.0, private URL scheme, matching media-browser identity, and build/
signing safeguards. No recovered companion functionality has been ported. The
localhost preview serves the same web assets bundled in the APK, with a browser-
only notice; it is not a separate implementation of the companion reader.

## App identity

- Display name: QuietShelf
- Application ID: `com.programmingdrak.quietshelf`
- Initial version: 0.1.0 / versionCode 1
- URL scheme: `quietshelf://`
- Upstream Kotlin/Java namespace remains `com.audiobookshelf.app` to keep merges small.
- Debug builds are unsigned; no automatic Android debug keystore is generated.
- Both build variants use the same application ID; distribute release builds only.

OpenID redirects now use `quietshelf://oauth`. A server's existing OpenID setup
may not permit this redirect; username/password login is the initial acceptance
path. Do not change a server's configuration without its owner's authorization.

## Original companion preserved

The earlier Quiet Shelf 0.1 app (`com.drake.companion`) is original, separate native
Android code, not a fork. Its EPUB rendering, local imports, audio service, local
reading/listening checkpoints, tests and synthetic fixtures are preserved in a
separate local Git repository and worktree. They are not copied into this public
repository. Its reading anchors are not EPUB CFI and cannot be sent directly as
Audiobookshelf reading positions. Integration requires explicit edition mapping
and migration tests; neither project's local data should be overwritten.

## Build

Use Node 20+, Java 21, Android platform 36, build-tools 35.0.0 and Gradle 8.11.1.
The native app now uses the Capacitor 7 CLI to match its version-7 runtime.

```sh
npm ci
npm run generate
CI=1 npx cap sync android
./scripts/build-android-local.sh :app:assembleRelease :app:lintRelease
```

The local helper accepts environment overrides for other machines. The output is
`android/app/build/outputs/apk/release/app-release-unsigned.apk` until explicitly
signed. An unsigned APK is not installable.

## Permanent signing identity

Create/select the release key only after explicit action-time approval. Proposed
new identity: RSA 3072, alias `quietshelf-release`, PKCS12, validity 30 years,
subject `CN=QuietShelf Android, O=ProgrammingDrak`. Store outside the repository
under `~/.local/share/quietshelf/signing/`, directory mode 0700 and key/password
files mode 0600. Never upload the key/password, print them, or commit them.
Back up the keystore and password privately before depending on update continuity.

`scripts/sign-release.sh` requires an existing approved keystore, environment
password, and pinned SHA-256 public certificate fingerprint. It zipaligns, signs,
verifies the fingerprint and APK signature, then emits the artifact. It refuses to
overwrite an existing artifact. Future releases must use the same key and app ID,
and increment versionCode. Losing the key prevents normal in-place updates.

## Upstream integration

`upstream` points to `advplyr/audiobookshelf-app`; `origin` points to
`ProgrammingDrak/audiobookshelf-app`. Keep upstream history intact. Fetch changes
and review their diff on a separate integration branch, resolve conflicts, run the
build/lint and acceptance checks, and open a review PR before merging. Never reset
the QuietShelf branch to upstream or overwrite companion files. Preserve GPL and
upstream notices; supply corresponding source with any distributed APK.

## Device acceptance (pending)

Use a non-admin authorized test account and synthetic/public-domain content.
No books, server credentials, or tokens belong in test evidence or releases.

1. Verify the APK certificate fingerprint and install on the authorized Pixel.
2. Connect to an approved reachable server; log in without exposing credentials.
3. Stream a fixture, pause/seek/resume, lock the screen, test audio focus and headset
   disconnection, then force-stop/reopen and verify resume position.
4. Download a fixture, verify completion, disconnect networking on the phone with
   the user's permission, and verify offline playback/resume. Restore networking.
5. Play/pause and verify server progress from a second client. Repeat after offline
   playback/reconnection and verify stale progress does not replace newer progress.
6. Install versionCode 2 signed by the same key over versionCode 1 and verify
   settings, downloads, and playback position survive.

Browser preview only demonstrates the UI; it does not establish Android codec,
notification, background playback, offline download or synchronization behavior.
