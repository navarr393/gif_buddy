# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app `gif_buddy` — a Giphy picker that uploads the chosen GIF to a networked "gif-buddy" device (identified by hostname/IP) over HTTP. Dart SDK `^3.11.5`. Dependencies: `giphy_picker` (search UI + Giphy models), `dio` (HTTP), `shared_preferences` (persist the device host). No state management or routing libraries — `Navigator.push` and `setState` only.

## Common commands

- `flutter pub get` — fetch deps after editing `pubspec.yaml`.
- `flutter run` — run on the currently selected device (`flutter devices` to list, `-d <id>` to pick).
- `flutter analyze` — static analysis using `flutter_lints` rules from `analysis_options.yaml`.
- `flutter test` — run widget tests in `test/` (currently fails, see below).
- `flutter build apk` / `flutter build ios` / `flutter build web` — platform builds.

## Architecture

Entry point `lib/main.dart`. The app is one screen plus a settings screen.

- `MyHomePage` (`lib/main.dart`) — holds the picked `GiphyGif?`, the current device `_host`, and a tri-state `_deviceOnline` (`null` = unknown, `true`/`false` = last ping result). On init it loads the host from prefs and pings. The FAB calls `_pickAndSend`, which: pings, opens `GiphyPicker.pickGif`, picks a URL via `_pickUrl` (prefers `original` unless its declared `size` exceeds `_maxBytes`, falls back to `downsized`), downloads the bytes via `GifBuddyClient`, and uploads. If the downloaded payload is still over `_maxBytes` (4 MiB), it retries once with the `downsized` URL before giving up with `PayloadTooLargeException`. A modal progress dialog is driven by a `ValueNotifier<double?>` wired to Dio's `onSendProgress`. The `AppBar` title shows the picked GIF's title when one is set, otherwise `widget.title` ("Gif Buddy"). An offline `MaterialBanner` renders above the body when `_deviceOnline == false`, with a Retry button.
- `GifBuddyClient` (`lib/gif_buddy_client.dart`) — Dio wrapper over the device's HTTP API. `ping()` GETs `http://<host>/` with 2 s timeouts. `downloadGif(url)` fetches arbitrary URLs as bytes. `uploadGif(bytes)` POSTs to `http://<host>/gif` as `application/octet-stream` (streamed from `Stream.fromIterable([bytes])`, with an explicit `Content-Length` header). Maps HTTP 413 to `PayloadTooLargeException` and any transport failure to `DeviceUnreachableException`. Each call constructs its own `Dio` instance and closes it in `finally` — there is no shared client.
- `DeviceSettings` (`lib/device_settings.dart`) — thin `SharedPreferences` wrapper. Key `device_host`, default `gif-buddy.local` (mDNS).
- `SettingsScreen` (`lib/settings_screen.dart`) — single text field bound to the host pref. `Save` persists and pops the new value, which `MyHomePage._openSettings` uses to refresh liveness.

### Constants worth knowing

- `_giphyApiKey` is hardcoded at the top of `lib/main.dart`. Treat it as a known leak rather than a secret.
- `_maxBytes = 4 * 1024 * 1024` (4 MiB) — the device's upload ceiling. This value is duplicated in the size-check logic; if the device limit changes, update both the constant and any expectations in tests.

## Assets

- `assets/gengar.gif` is still present but no longer rendered anywhere — leftover from the original scaffold. Safe to delete if you don't have a use for it.
- `pubspec.yaml` declares `assets/` as a directory entry, so files dropped into `assets/` are picked up automatically. New top-level asset folders require editing `pubspec.yaml` and re-running `flutter pub get`.

## Tests

`test/widget_test.dart` is **stale `flutter create` boilerplate** — it asserts a counter UI (`find.text('0')`, tapping `Icons.add`) that has never existed in this app. `flutter test` will fail until this is rewritten against the real `MyHomePage`. Don't treat the failure as a regression you caused. Rewriting it likely requires faking `GifBuddyClient` and stubbing `SharedPreferences` (`SharedPreferences.setMockInitialValues({})`).

## Platform scaffolding

Project includes `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/` folders from `flutter create`. Touch these only when configuring platform-specific behavior (signing, Info.plist, permissions, icons, network entitlements for cleartext HTTP to the device); day-to-day Dart work stays in `lib/`.
