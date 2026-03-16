# SocketSense iOS

An iOS charger monitoring app built with **UIKit + MVVM** — alerts you when your charger is accidentally removed before the wall socket is switched on.

---

## 📁 Project Structure

```
SocketSense/
├── AppDelegate.swift                  # App entry, notification permission
│
├── Models/
│   └── Models.swift                   # ChargingEvent, SocketSenseSettings, AlertRecord
│
├── ViewModels/
│   └── MainViewModel.swift            # MVVM state, settings persistence, Combine bindings
│
├── Services/
│   └── ChargingMonitorService.swift   # Core battery/charging monitor, alert trigger, sound
│
├── Views/
│   ├── Components.swift               # Reusable UI: SSCardView, SSToggleRow, SSLabeledSlider...
│   ├── MainViewController.swift       # Root screen, binds ViewModel → UI
│   ├── StatusCardView.swift           # Live status: alerts count, plug/unplug times
│   ├── SensitivityCardView.swift      # Sensitivity slider (1s–30s)
│   ├── LowBatteryCardView.swift       # Low battery toggle + threshold slider
│   └── BottomCardViews.swift          # Reliability card, Alert sound picker, Footer
│
└── Info.plist                         # Background modes, notification usage strings
```

---

## ✅ Features

| Feature | Status |
|---|---|
| Charger plug/unplug detection | ✅ Via `UIDevice.batteryStateDidChangeNotification` |
| Alert if unplugged within N seconds | ✅ Configurable 1–30s slider |
| Alert count + last event display | ✅ Live updated every 1s |
| Charging duration tracking | ✅ h/m/s format |
| Battery % + charge rate | ✅ Real-time |
| Low battery threshold alert | ✅ Configurable 1–100% |
| Remind every 1% drop | ✅ Toggle |
| Background app refresh | ✅ Info.plist configured |
| Local push notification on alert | ✅ UNUserNotificationCenter |
| Alert sound (default + custom audio) | ✅ UIDocumentPickerViewController |
| Settings persistence | ✅ UserDefaults via Codable |
| MVVM architecture | ✅ Combine `@Published` + `sink` |
| Dark theme matching Android app | ✅ Custom UIColor palette |

---

## 🛠️ Setup in Xcode

1. **Create a new Xcode project** → iOS → App → UIKit → Swift
2. **Delete** the auto-generated `ViewController.swift` and `Main.storyboard`
3. **Copy** all `.swift` files into your project, maintaining the folder structure
4. **Replace** `Info.plist` with the provided one (or merge the keys)
5. In **Info.plist**, set `UIMainStoryboardFile` key to **blank/delete it** (we use code-based UI)
6. In **AppDelegate**, ensure `window` setup is present (provided)
7. Build & Run on a **real device** (battery APIs don't work on Simulator)

---

## ⚠️ iOS vs Android Differences

| | Android | iOS |
|---|---|---|
| Battery current (mA) | Exact via `BatteryManager` | Estimated (~180mA typical) |
| Background execution | Service stays alive | Background App Refresh (limited) |
| Battery optimization disable | Direct setting | Open iOS Settings |
| Charger detection | Exact intent | `batteryStateDidChangeNotification` |

> **Note**: iOS restricts background execution. For the most reliable experience, keep the app in foreground or use a notification extension.

---

## 🏗️ Architecture

```
View (UIKit)
  └─ observes → ViewModel (@Published + Combine)
                  └─ calls → Service (ChargingMonitorService)
                               └─ wraps → UIDevice battery APIs
                                          UNUserNotificationCenter
                                          AVAudioPlayer
```

- **No Storyboards** — 100% programmatic UIKit
- **MVVM** with Combine for reactive bindings
- **Singleton Service** (`ChargingMonitorService.shared`) for system-level monitoring
- **Codable Settings** persisted to UserDefaults
