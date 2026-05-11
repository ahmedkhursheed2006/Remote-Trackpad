# Remote Trackpad & Tablet

A high-performance, low-latency solution that turns your smartphone into a liquid-smooth digitizer and trackpad for your laptop.

## 🚀 Features

- **Liquid Motion Smoothing**: Uses Exponential Moving Average (EMA) algorithms to eliminate jitter and provide a "premium" tactile feel.
- **Auto-Discovery**: No need to type IP addresses. The mobile app automatically scans your local network for the desktop server.
- **Dual Modes**:
  - **Trackpad Mode**: Standard relative movement with adjustable sensitivity.
  - **Tablet Mode**: Absolute 1:1 mapping of your phone screen to your laptop display (perfect for drawing).
- **Advanced Controls**:
  - **Hold to Drag**: Dedicated UI button for easy window dragging or selection.
  - **Right Click**: Quick-access button for contextual menus.
  - **Tap-to-Click**: Integrated gesture support.
- **High Performance**: Built with Flutter's raw `Listener` widget and Python's `pynput` for sub-millisecond response times.

---

## 🛠️ Project Structure

- `/flutter_app`: The mobile client built with Flutter.
- `/python_server`: The desktop background service built with Python.

---

## 💻 Setup Instructions

### 1. Desktop Server (Windows/macOS/Linux)
The server must be running on your laptop to receive input.

**Using the Executable (Windows):**
- Navigate to `python_server/dist/`.
- Run `RemoteTrackpad.exe`.

**Running from Source:**
- Ensure Python 3.x is installed.
- Install dependencies: `pip install -r python_server/requirements.txt`
- Run: `python python_server/server.py`

### 2. Mobile App (Android)
- **Install APK**: Copy `flutter_app/build/app/outputs/flutter_apk/app-release.apk` to your phone and install it.
- **Development**: Or run `flutter run --release` from the `flutter_app` folder.

---

## 📡 Connection Guide

### Option A: Wi-Fi (Same Network)
1. Ensure both devices are on the same Wi-Fi.
2. Open the app and tap the **Sync/Refresh** icon to auto-discover your laptop.
3. If discovery fails, enter your laptop's Local IP manually in Settings.

### Option B: USB Cable (Lowest Latency)
1. Connect your phone via USB.
2. Enable **USB Tethering** on your phone.
3. In the app settings, enter the laptop's Tethering IP (usually `192.168.x.x`).

---

## ⚠️ Troubleshooting

- **Firewall**: Ensure UDP ports `6000` and `6001` are allowed through your Windows/System firewall.
- **IP Address**: If you can't connect, run `ipconfig` (Windows) or `ifconfig` (Mac/Linux) to verify your laptop's current IP.
- **Sensitivity**: Adjust the slider in the mobile app settings if the cursor moves too slow or too fast.

---

## 📜 Protocol Definition
The app communicates via lightweight UDP strings:
`x_coord, y_coord, action_type, mode`
- `action_type`: `hover`, `down`, `up`, `right_click`
- `mode`: `trackpad`, `tablet`
