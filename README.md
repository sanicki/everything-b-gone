# Everything-B-Gone

A single-purpose IR "kill switch" remote for Android. Pick a device type
and brand, hit **Power** or **Mute**, and it blasts every matching signal
from the [Flipper-IRDB](https://github.com/Lucaslhm/Flipper-IRDB)
community database through your phone's built-in IR emitter, a USB IR
dongle, or an audio-to-IR adapter — until the TV turns off (or shuts up).

No custom remote building, no learning mode, no bruteforce tooling —
just Power and Mute.

> **Before shipping:** the Android package ID is currently the placeholder
> `com.example.everythingbgone` (see `android/app/build.gradle`). Replace
> it with a real reverse-domain ID you control before distributing this
> app.

## How it works

- **Data source**: a headless client permanently pointed at
  [Lucaslhm/Flipper-IRDB](https://github.com/Lucaslhm/Flipper-IRDB), a
  community-maintained collection of Flipper Zero `.ir` files organized by
  Device Type → Brand → model file.
- **Caching**: the repo's full Device Type / Brand directory tree is
  fetched once (via a single recursive Git tree API call) and cached
  locally; each Device Type's `.ir` file contents are fetched and parsed
  lazily, the first time that type is actually selected. Settings shows
  when each type was last cached, with per-type and full-tree refresh
  actions.
- **Filters**: multiselect Device Type and Brand checklists (each with an
  "All" option). Device Type defaults to "TVs"; Brands defaults to "All".
  A background scan determines which Device Types/Brands have at least
  one usable Power or Mute signal and hides the ones that don't, without
  blocking the initial screen.
- **Power**: for each matching `.ir` file, prefers a signal named
  "power" (case-insensitive substring match); falls back to an
  "off"-named signal only if the file has no power match. Cycles through
  every match across the current filter selection, one at a time, through
  whichever transmitter is currently active.
- **Mute**: same cycling behavior, matching "mute"-named signals.
- **Quick access**: Quick Settings tiles, Android Device Controls, and a
  home-screen widget all fire the same Power/Mute cycle directly —
  no need to open the app.

## Transmitter hardware

Three transmit paths, auto-detected on first launch (silently selected if
only one is available; a picker only appears when there's a real choice):

- **Internal** — the device's built-in IR blaster (`ConsumerIrManager`), if
  it has one.
- **USB IR dongle** — tested against a Tiqiaa TView dongle, with USB
  discovery, permission handling, and an Auto Switch option that prefers
  USB over internal whenever a dongle is attached.
- **Audio** — mono 1-LED or stereo anti-phase 2-LED adapters plugged into
  the headphone jack.

Settings > IR Transmitter lets you see and override which path is active.

## Distribution

Sideload-only via [Obtainium](https://github.com/ImranR98/Obtainium),
tracking this repo's GitHub Releases directly — no Play Store, no
F-Droid metadata. Release notes on each GitHub Release are the only
"changelog" a user sees; check the Releases page for what changed.

## Building

This repo vendors Flutter as a git submodule at `.flutter/` — it's the
project's single source of truth for the Flutter SDK version, so don't
install a separately-pinned Flutter alongside it.

```bash
git clone --recurse-submodules <this-repo>
cd everything-b-gone
./.flutter/bin/flutter pub get
./.flutter/bin/flutter build apk --release
```

CI (`.github/workflows/`) builds a debug APK on every pull request, and a
manual `Release` workflow (patch/minor/major bump) builds, tests, tags,
and publishes a signed release APK when the `KEYSTORE_BASE64`,
`KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD` repo secrets are
configured — otherwise it falls back to a clearly-labeled debug-signed
build.

## License

GPL-3.0, same as the codebase this was built from. See
[LICENSE](LICENSE) for the full text.

## Acknowledgments

Everything-B-Gone is a heavily stripped-down and rebuilt derivative of
[iodn/android-ir-blaster](https://github.com/iodn/android-ir-blaster) —
the general-purpose IR remote-building app whose transmitter/encoding
engine this project is built on. That project is itself a fork of
[TalkingPanda0/osram-remote](https://github.com/TalkingPanda0/osram-remote).
Thanks to both for the foundational work.

Device signal data comes from the
[Flipper-IRDB](https://github.com/Lucaslhm/Flipper-IRDB) community
database.
