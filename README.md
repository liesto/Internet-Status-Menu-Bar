# Internet Status App

A small macOS menu bar app that pings `8.8.8.8` once per second and shows live latency, packet loss, and a 60-sample sparkline. Built for spotty Western North Carolina internet.

## Where the code lives

- **Live source (what Xcode edits):** `InternetStatus/InternetStatus/`
  - `PingBarApp.swift` — `@main` entry, `AppDelegate`, `NSStatusItem` (the colored dot + ms in the menu bar)
  - `PingMonitor.swift` — wraps `/sbin/ping`, parses output, tracks rolling history, computes status
  - `ContentView.swift` — the popover UI (stats + Swift Charts sparkline + Quit)
- **Xcode project:** `InternetStatus/InternetStatus.xcodeproj`
- **Scaffold archive:** `Sources/` — the original files that were dragged into Xcode. Not the live copy. Safe to ignore or delete.

## Daily install (run without Xcode + launch on login)

After making any code change you want to ship to your menu bar:

### 1. Stop the run from Xcode

Click the **⏹ stop button** at the top of Xcode (or press `Cmd + .`).

### 2. Find the built app

In Xcode's top menu bar: **Product → Show Build Folder in Finder**.

Finder opens. Double-click into **Products**, then **Debug**. You'll see `InternetStatus.app`.

### 3. Move it to /Applications

Drag `InternetStatus.app` to **Applications** in Finder's sidebar. If prompted to replace an older copy, click **Replace**.

### 4. Quit Xcode

With Xcode focused, press `Cmd + Q`.

### 5. Launch the standalone app

Press `Cmd + Space`, type **InternetStatus**, hit Enter. The colored dot appears in the menu bar — now running independently of Xcode.

### 6. (One-time) Add to Login Items

Apple menu → **System Settings…** → **General** → **Login Items & Extensions** → under **Open at Login**, click **+** → pick **InternetStatus** in `/Applications` → **Open**.

From now on the app launches every time you log in or restart.

## Updating the app

When you change code:

1. Open `InternetStatus/InternetStatus.xcodeproj` in Xcode.
2. Edit the file you want to change.
3. Press `Cmd + R` to run and verify in the menu bar.
4. When happy, repeat the **Daily install** steps above to replace the copy in `/Applications`.
5. Before re-copying, click the **menu bar dot → Quit** so the running standalone version exits. Then drag the fresh `.app` over.

## Tweaks

- **Change the host**: in `PingMonitor.swift`, the `init(host:)` default is `"8.8.8.8"`. Change the default, or pass a different host from `PingBarApp.swift` (`PingMonitor()` → `PingMonitor(host: "1.1.1.1")`).
- **Change the interval**: in `PingMonitor.swift`, the `Task.sleep(nanoseconds: 1_000_000_000)` line — `1_000_000_000` ns = 1 second. Bump to `2_000_000_000` for every-2-seconds.
- **Status thresholds**: see `updateStatus()` in `PingMonitor.swift`. Currently:
  - **Green** (good): avg < 100 ms, < 2 timeouts in last 10
  - **Yellow** (slow): 100–300 ms avg
  - **Orange** (degraded): > 300 ms or 2–4 timeouts
  - **Red** (down): 5+ timeouts in last 10

## Original Xcode project setup (already done)

Kept here as a reference in case you ever need to recreate the project from scratch.

1. Xcode → **File → New → Project…** → **macOS → App** → **Next**.
2. Product Name `InternetStatus`, Team = personal team, Interface SwiftUI, Language Swift, Storage None, Include Tests off.
3. Save inside this folder.
4. Delete the auto-generated `InternetStatusApp.swift` and `ContentView.swift`.
5. Drag the three files from `Sources/` into the project. **Copy items if needed** ✓, target **InternetStatus** ✓.
6. Project → target **InternetStatus** → **Signing & Capabilities** → click the **x** on **App Sandbox** to remove it (required so the app can spawn `/sbin/ping`).
7. Confirm **General → Minimum Deployments → macOS 13.0** or newer.
8. `Cmd + R` to build and run.
