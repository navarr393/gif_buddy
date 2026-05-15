# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app `gif_buddy` — currently a single-screen scaffold that displays `assets/gengar.gif` inside a `MaterialApp` / `Scaffold`. Dart SDK `^3.11.5`. No state management, networking, or routing libraries yet; dependencies are limited to `flutter`, `cupertino_icons`, and `flutter_lints`.

## Common commands

- `flutter pub get` — fetch deps after editing `pubspec.yaml`.
- `flutter run` — run on the currently selected device (`flutter devices` to list, `-d <id>` to pick).
- `flutter analyze` — static analysis using `flutter_lints` rules from `analysis_options.yaml`.
- `flutter test` — run the widget tests in `test/`.
- `flutter test test/widget_test.dart --plain-name "Counter"` — run a single test by name.
- `flutter build apk` / `flutter build ios` / `flutter build web` — platform builds.

## Architecture notes

- Entry point: `lib/main.dart`. `MyApp` (root `MaterialApp`) → `MyHomePage` (`StatefulWidget` whose state currently renders a static column). Title is passed in but the `AppBar` hardcodes "Gif Buddy" — be aware these can drift.
- Assets are declared via the `assets:` directory entry in `pubspec.yaml` (not per-file). New asset files dropped into `assets/` are picked up automatically, but adding new top-level asset folders requires editing `pubspec.yaml` and re-running `flutter pub get`.
- `test/widget_test.dart` is **stale boilerplate** from `flutter create`: it asserts a counter UI (`find.text('0')`, tapping `Icons.add`) that does not exist in `main.dart`. Expect `flutter test` to fail until this is rewritten. Don't treat it as a regression you caused.

## Platform scaffolding

Project includes `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/` folders from `flutter create`. Touch these only when configuring platform-specific behavior (signing, Info.plist, permissions, icons); day-to-day Dart work stays in `lib/`.
