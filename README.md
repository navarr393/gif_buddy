# GIF Buddy — Flutter companion app

Send GIFs to an ESP32 badge's round TFT and scrolling text to its optional LED
matrix over local Wi-Fi. This app works with the GIF Buddy receiver in the
`e_badge` Arduino sketch.

## What you need

- Flutter installed on your development computer.
- An iOS or Android development environment and a simulator/emulator or phone.
- Your own GIPHY API key for searching/picking GIFs.
- An ESP32 running the compatible firmware, connected to a reachable local network.
- Internet access for GIPHY; local network access for sending to the badge.

The full badge GIF receiver requires PSRAM. Follow the **e_badge firmware README**
for supported boards, TFT wiring, Arduino settings, and flashing. Installing this
Flutter app does not flash or configure the ESP32's Wi-Fi credentials.

## 1. Get Flutter

If Flutter is not installed, follow the official
[Flutter installation guide](https://docs.flutter.dev/install).
Choose your operating system and complete setup for the platform you want to run.
There is no separate Dart SDK installation required when using Flutter.

After installation, open a terminal and check your setup:

```sh
flutter --version
flutter doctor
```

Resolve issues reported for your intended target platform. iOS development
requires macOS and Xcode; Android development requires the Android tooling.
Use the official installation guide for those platform-specific steps.

This project's `pubspec.yaml` requires Dart **^3.11.5**. Use a Flutter SDK that
includes a compatible Dart version. If dependency resolution reports an SDK
mismatch, update Flutter rather than lowering the project's SDK constraint.

## 2. Get a GIPHY API key

1. Visit the [GIPHY Developer Dashboard](https://developers.giphy.com/dashboard/)
   and create an account or sign in.
2. Choose **Create an API Key** (or the dashboard's create-app flow).
3. If asked to choose an integration, choose **API** for this app's API-based picker.
4. Enter your app name and the details requested by GIPHY, then create the key.
5. Copy the API key from your dashboard.

New keys are beta/development keys with usage limits. Check the dashboard and
[GIPHY API quick-start guide](https://developers.giphy.com/docs/api/quick-start-guide/)
for current limits and the production-upgrade process. If distributing the app,
follow GIPHY's platform-specific key and production requirements.

### Put the key in the app

Open `lib/main.dart` and replace the empty `_giphyApiKey` value:

```dart
const _giphyApiKey = 'YOUR_GIPHY_API_KEY';
```

Hardcoding your own development key here is supported by the current app. Do not
paste it into the ESP32 firmware or use the OpenWeather key from the weather
sketch—those are different services. Avoid committing your personal key to a
public repository. Rebuild/restart the app after changing it.

**Text sending does not use GIPHY and does not need a GIPHY key.** The bundled
`assets/gengar.gif` test send also bypasses GIPHY search/download.

## 3. Get dependencies and run

Open a terminal in the app folder containing `pubspec.yaml`:

```sh
cd /path/to/gif_buddy
flutter pub get
flutter devices
flutter run
```

If more than one target is available, select it explicitly using the ID printed
by `flutter devices`:

```sh
flutter run -d DEVICE_ID
```

Replace `DEVICE_ID` with the real ID. Start a simulator/emulator or connect your
phone first. A simulator still needs access to the **physical badge** over the
host computer's network; it does not simulate the ESP32 hardware.

### iOS notes

The current project uses **Swift Package Manager** for its plugins. Open
`ios/Runner.xcworkspace` if you need to inspect it in Xcode. Do not restore old
CocoaPods references or run `pod install` just to follow outdated setup steps.

For a physical iPhone, configure signing with your own team in Xcode if required
and allow local-network access when prompted. Simulator builds do not require
physical-device signing. The iPhone 17 simulator build/launch has been verified;
Android and physical-phone behavior have not been verified to the same extent.

## 4. Connect to the badge

1. Flash and start the compatible `e_badge` firmware.
2. Open Arduino Serial Monitor at **115200 baud**. Wait for Wi-Fi to connect and
   note the address printed with `GIF Buddy: http://.../`.
3. Put your phone (or simulator's host computer) on a network that can reach it.
   Avoid guest Wi-Fi/client isolation that blocks device-to-device traffic.
4. Open the app's **Settings** using the gear icon.
5. Enter **gif-buddy.local** or the badge's IP address, such as `192.168.1.42`.
   Enter only the host/IP—**no `http://`, path, or trailing slash**.
6. Save the setting and use Retry if the app reports the device offline.

The host setting is saved between app launches. If `.local` name resolution
fails, use the IP from Serial Monitor. If multiple GIF Buddy boards share the
hostname, use the IP of the board you intend to control. DHCP can change that IP
when the device reconnects.

The badge's Wi-Fi credentials live in its `BadgeSecrets.h`; they are not entered
in this app. The app communicates with the badge using local HTTP on port 80.

## 5. Send a GIF

1. Tap the **search button** to open the GIPHY picker.
2. Search for and select a GIF.
3. Wait for the download/upload and success message.
4. The TFT displays the uploaded GIF; the LED text continues independently.

The app prefers GIPHY's animated **200px-wide** rendition to suit the badge's
decoder and memory. The transfer limit is **4 MB**. The current firmware also
limits GIF width to **480px** and height to **2048px**. Available PSRAM can impose
a lower practical limit, especially while replacing a large GIF.

The badge fits the image into its 240×240 screen while preserving proportions.
Some images have black margins, and the round screen hides the square canvas's
corners. The app preview and the physical round display need not look identical.

For a quick test without a GIPHY key, use the **bug icon** in the app bar to send
the bundled `assets/gengar.gif` file. This tests app-to-device transfer directly.

## 6. Send scrolling text

1. Enter a message in **Scrolling badge text**.
2. Tap **Send text**.
3. The badge's LED matrix scrolls the new message.

- Maximum **160 printable ASCII characters** (letters, numbers, spaces, punctuation).
- Emoji, accented characters, and newlines are not supported by the current endpoint.
- Send an **empty field** to clear the LEDs.
- Text color, brightness, speed, and matrix orientation are set in the Arduino
  firmware's `MatrixScroller.h`, not the app.
- With a TFT-only DevKit, GIFs work if PSRAM is available, but text has no visible
  output because the LED matrix is absent.

Received GIFs and text are stored in the badge's RAM. Resetting or powering off
restores its startup defaults. **No LittleFS upload is needed for app-sent content.**

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `flutter: command not found` | Finish the official Flutter installation/PATH setup, then reopen the terminal. |
| SDK constraint / dependency resolution failure | Check `flutter --version` against the Dart requirement in `pubspec.yaml`. |
| No devices found | Start the simulator/emulator or connect a configured phone; run `flutter doctor` and `flutter devices`. |
| GIPHY picker cannot load results | Confirm your key in `lib/main.dart`, internet connectivity, and your key's dashboard status/usage limits. |
| Device appears offline | Check the firmware is running, the host/IP is correct, both endpoints can reach each other, and local-network access is allowed. Try the IP instead of `.local`. |
| GIF upload rejected as too large | Choose a smaller GIF; the device may have less free PSRAM than the 4 MB transfer ceiling. |
| GIF received but display remains blank | Check the badge's Serial Monitor for decoding errors and confirm PSRAM is enabled in its board settings. |
| Text rejected | Remove emoji/newlines/non-ASCII characters and keep the message within 160 characters. |
| Text endpoint returns 404 | The board may still run the original GIF-only firmware; flash the updated `e_badge` receiver. |
| `No Xcode build settings have been found` | Inspect the detailed output with `flutter run -v`. In this project, device-only `SUPPORTED_PLATFORMS` caused the failure; keep `iphoneos iphonesimulator` enabled and verify the simulator runtime is installed. |

Android debug runs use the development manifest's network permission. Before
shipping an Android release, ensure `android.permission.INTERNET` is declared
in the **main** manifest as well. This README covers the development run; it does
not claim a tested store/release build. The badge uses unauthenticated HTTP on a
trusted local network, not a public internet service.

## Development checks

From the project root:

```sh
flutter analyze
flutter test
```

Client/widget tests cover encoded text, clearing, unsupported/overlong text,
device rejection, and the text controls. Tests do not replace testing real GIF
playback and network access on the badge.

## Important files

| File | Purpose |
| --- | --- |
| `lib/main.dart` | UI, GIPHY key, GIF selection/upload, text controls |
| `lib/gif_buddy_client.dart` | Badge HTTP client and transfer/error handling |
| `lib/device_settings.dart` | Saved badge hostname/IP |
| `lib/settings_screen.dart` | Device settings UI |
| `assets/gengar.gif` | Bundled GIF for direct transfer testing |
| `pubspec.yaml` | SDK constraint, dependencies, assets |
| `test/` | Client and widget tests |

## Official resources

- [Install Flutter](https://docs.flutter.dev/install)
- [GIPHY Developer Dashboard](https://developers.giphy.com/dashboard/)
- [GIPHY API quick-start guide](https://developers.giphy.com/docs/api/quick-start-guide/)
