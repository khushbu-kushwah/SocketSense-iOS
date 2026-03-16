<div align="center">

# ⚡ SocketSense

### Never forget to switch on the wall socket again.

SocketSense monitors your iPhone's charger and plays an alert the moment it detects the charger was removed too quickly — which usually means you plugged in but forgot to flip the wall switch.

![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift)
![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue?style=flat-square&logo=apple)
![Architecture](https://img.shields.io/badge/Architecture-MVVM-purple?style=flat-square)
![UI](https://img.shields.io/badge/UI-UIKit%20%28Programmatic%29-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)

</div>

---

## 📱 Screenshots

> Coming soon — real device screenshots

---

## 🧠 The Problem

In many countries, wall sockets have an on/off switch. It's easy to plug in your charger and walk away — without actually flipping the switch. Your phone sits there all night, not charging.

SocketSense solves this by:
1. Detecting when your charger is plugged in
2. Starting a timer
3. If the charger is removed within your set threshold (e.g. 10 seconds), it assumes you forgot to switch on the socket — and **fires an alert immediately**

---

## ✨ Features

| Feature | Details |
|---|---|
| ⚡ Charger unplug detection | Real-time via `UIDevice` battery APIs + active polling |
| ⏱ Configurable sensitivity | Alert if unplugged within 1–30 seconds |
| 🔋 Low battery alerts | Configurable threshold (1–100%) |
| 📊 Live charging stats | Duration, charge rate, battery %, mA |
| 🔔 Critical notifications | Fires even in Do Not Disturb mode |
| 🎵 Custom alert sound | Pick any audio file from your device |
| 🌙 Background monitoring | Silent audio trick keeps app alive in background |
| 💾 Persistent settings | All preferences saved via `Codable` + `UserDefaults` |
| 🌑 Dark UI | Fully custom dark theme, no system default |

---

## 🏗️ Architecture

Built with **MVVM** + **Combine**, fully programmatic UIKit — zero Storyboards.

```
┌─────────────────────────────────────────────────────┐
│                        VIEW                         │
│  MainViewController → StatusCard, SensitivityCard  │
│           LowBatteryCard, AlertSoundCard            │
└──────────────────┬──────────────────────────────────┘
                   │ @Published bindings (Combine)
┌──────────────────▼──────────────────────────────────┐
│                    VIEWMODEL                        │
│              MainViewModel.swift                    │
│     State management, settings, UI data formatting  │
└──────────────────┬──────────────────────────────────┘
                   │ delegates + callbacks
┌──────────────────▼──────────────────────────────────┐
│                    SERVICE                          │
│          ChargingMonitorService.swift               │
│  UIDevice APIs · AVAudioSession · BGTaskScheduler   │
│  UNUserNotificationCenter · Polling Timer           │
└─────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
SocketSense/
│
├── AppDelegate.swift               # App entry, BGTask registration, window setup
├── SceneDelegate.swift             # Minimal (window handled by AppDelegate)
│
├── Models/
│   └── Models.swift                # ChargingEvent, SocketSenseSettings, AlertRecord
│
├── ViewModels/
│   └── MainViewModel.swift         # @Published state, Combine bindings, settings
│
├── Services/
│   └── ChargingMonitorService.swift # Core engine — polling, audio, alerts, bg tasks
│
└── Views/
    ├── Components.swift             # Design system: SSCardView, SSToggleRow, SSLabeledSlider
    ├── MainViewController.swift     # Root VC — wires ViewModel → all cards
    ├── StatusCardView.swift         # Live status: alert count, times, battery stats
    ├── SensitivityCardView.swift    # Sensitivity slider (1s–30s)
    ├── LowBatteryCardView.swift     # Low battery toggle + threshold slider
    └── BottomCardViews.swift        # Reliability info, alert sound picker, footer
```

---

## 🔧 How Background Monitoring Works

iOS kills background apps to save battery. SocketSense uses a layered strategy to stay alive:

```
App goes to background
        │
        ├─ 1. AVAudioSession (.playback) + silent audio loop
        │      → Keeps app process alive (same as music/navigation apps)
        │
        ├─ 2. UIBackgroundTask
        │      → Requests extra execution time from iOS
        │
        ├─ 3. 1-second polling timer (RunLoop.main)
        │      → Actively reads UIDevice.batteryState every second
        │      → iOS blocks battery *notifications* in background,
        │         but cannot block direct property reads
        │
        └─ 4. BGAppRefreshTask
               → iOS wakes app periodically as a fallback
```

> **Note:** If the app is fully force-closed by the user, monitoring stops.
> The app sends a notification when terminated reminding the user to reopen it.

---

## 🚀 Setup & Installation

### Requirements
- Xcode 15+
- iOS 17.0+ deployment target
- **Real device required** — battery APIs don't work on Simulator

### Steps

1. **Clone the repo**
   ```bash
   git clone https://github.com/yourusername/SocketSense.git
   cd SocketSense
   ```

2. **Open in Xcode**
   ```bash
   open SocketSense.xcodeproj
   ```

3. **Configure signing**
   - Select your target → Signing & Capabilities
   - Choose your Apple Developer team

4. **Add capabilities** (if not already present)
   - Signing & Capabilities → `+` Capability
   - Add **Background Modes** → check:
     - ✅ Audio, AirPlay, and Picture in Picture
     - ✅ Background fetch
     - ✅ Background processing

5. **Add Info.plist key**
   - Target → Info tab → add `BGTaskSchedulerPermittedIdentifiers` (Array)
   - Item 0: `com.socketsense.monitor`

6. **Build & Run on your iPhone**
   ```
   Cmd + R
   ```

---

## ⚡ Usage

1. Open the app — monitoring starts automatically
2. Plug in your charger
3. Put the app in **background** (press Home)
4. If you accidentally unplug the charger within your set threshold — alarm fires!

**Tip:** Keep the app running in the background for best results. Do not force-close it.

---

## 📊 iOS vs Android Comparison

| Capability | Android (original) | iOS (this app) |
|---|---|---|
| Charger detection | `BatteryManager` intent | `UIDevice` polling |
| Background execution | Foreground Service (always alive) | Silent audio + BGTask |
| Force-closed monitoring | ✅ Works | ❌ iOS restriction |
| Battery current (mA) | Exact value | Estimated |
| Critical alerts | Default | `interruptionLevel: .critical` |

---

## 🛠️ Tech Stack

| Technology | Usage |
|---|---|
| **Swift 5.9** | Primary language |
| **UIKit** | All UI, fully programmatic |
| **Combine** | Reactive bindings (`@Published`, `sink`) |
| **AVFoundation** | Audio session, silent audio, alarm playback |
| **BackgroundTasks** | `BGAppRefreshTask` for periodic wakeup |
| **UserNotifications** | Local + critical push alerts |
| **AudioToolbox** | System sound + haptic fallback |
| **UserDefaults + Codable** | Settings persistence |

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first.

1. Fork the repo
2. Create your branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 👩‍💻 Author

**Khushbu Kushwah**
- This project was built as a personal iOS utility app using Swift, UIKit, and MVVM architecture.

---

<div align="center">
Made with ❤️ and too many charger-related frustrations
</div>
